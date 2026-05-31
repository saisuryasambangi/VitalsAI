import SwiftUI
@preconcurrency import HealthKit
import UIKit

struct SettingsView: View {
    @AppStorage("preferred_provider") private var preferredProvider: String = LLMProviderType.anthropic.rawValue
    @AppStorage("user_age") private var userAge: Int = 30
    @AppStorage("user_sex") private var userSex: String = "unknown"
    @State private var permissionStatuses: [HealthPermission] = []

    // Notification state
    @State private var reminderEnabled = false
    @State private var reminderWeekday: Int = 2   // Monday
    @State private var reminderHour: Int = 9
    @State private var nextFireDate: Date? = nil
    @State private var notifAuthDenied = false

    var body: some View {
        Form {
            // MARK: Your Profile
            Section {
                Stepper("Age: \(userAge)", value: $userAge, in: 18...100)
                Picker("Biological Sex", selection: $userSex) {
                    ForEach(UserProfile.BiologicalSex.allCases, id: \.rawValue) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
            } header: {
                Text("Your Profile")
            } footer: {
                Text("Used to tailor health benchmarks in your AI analysis.")
            }

            // MARK: AI Provider
            Section {
                Picker("AI Provider", selection: $preferredProvider) {
                    ForEach(LLMProviderType.allCases, id: \.rawValue) { provider in
                        Text(provider.displayName)
                            .tag(provider.rawValue)
                    }
                }
                .pickerStyle(.menu)
                if let selected = LLMProviderType(rawValue: preferredProvider), !selected.isAvailable {
                    Label("This provider is not yet available", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("Anthropic Claude uses your API key. On-device inference requires iOS 26.")
            }

            // MARK: Health Data
            Section("Health Data") {
                ForEach(permissionStatuses) { perm in
                    HStack {
                        Label(perm.name, systemImage: perm.iconName)
                        Spacer()
                        Text(perm.statusLabel)
                            .font(.caption)
                            .foregroundStyle(perm.statusColor)
                    }
                }
                Button {
                    if let url = URL(string: "x-apple-health://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Health App", systemImage: "heart.fill")
                }
            }

            // MARK: Notifications
            Section {
                Toggle("Weekly Reminder", isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, enabled in
                        Task { await toggleReminder(enabled) }
                    }

                if reminderEnabled {
                    Picker("Day", selection: $reminderWeekday) {
                        ForEach(weekdayOptions, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                    .onChange(of: reminderWeekday) { _, _ in reschedule() }

                    Picker("Time", selection: $reminderHour) {
                        ForEach([6, 7, 8, 9, 10, 12, 18, 20], id: \.self) { h in
                            Text(hourLabel(h)).tag(h)
                        }
                    }
                    .onChange(of: reminderHour) { _, _ in reschedule() }

                    if let next = nextFireDate {
                        LabeledContent("Next reminder", value: next.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if notifAuthDenied {
                    Label("Notifications are disabled. Enable them in Settings.", systemImage: "bell.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("A weekly nudge to run your health analysis.")
            }

            // MARK: About
            Section("About") {
                LabeledContent("Version", value: appVersion)
                Link(destination: URL(string: "https://github.com/saisuryasambangi/VitalsAI")!) {
                    Label("View on GitHub", systemImage: "link")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Built with Apple Foundation Models & Anthropic Claude")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            loadPermissions()
            await loadNotificationState()
        }
    }

    // MARK: - Notification Helpers

    private struct WeekdayOption { let label: String; let value: Int }
    private var weekdayOptions: [WeekdayOption] {
        [("Sunday",1),("Monday",2),("Tuesday",3),("Wednesday",4),
         ("Thursday",5),("Friday",6),("Saturday",7)].map { WeekdayOption(label: $0.0, value: $0.1) }
    }

    private func hourLabel(_ h: Int) -> String {
        let d = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
        return d.formatted(.dateTime.hour().minute())
    }

    private func loadNotificationState() async {
        let status = await NotificationService.shared.authorizationStatus()
        notifAuthDenied = status == .denied
        reminderEnabled = await NotificationService.shared.isReminderScheduled()
        nextFireDate = await NotificationService.shared.nextFireDate()
    }

    private func toggleReminder(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                NotificationService.shared.scheduleWeeklyReminder(weekday: reminderWeekday, hour: reminderHour)
                nextFireDate = await NotificationService.shared.nextFireDate()
                notifAuthDenied = false
            } else {
                reminderEnabled = false
                notifAuthDenied = true
            }
        } else {
            NotificationService.shared.cancelWeeklyReminder()
            nextFireDate = nil
        }
    }

    private func reschedule() {
        NotificationService.shared.scheduleWeeklyReminder(weekday: reminderWeekday, hour: reminderHour)
        Task { nextFireDate = await NotificationService.shared.nextFireDate() }
    }

    // MARK: - Version

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let store = HKHealthStore()
        let identifiers: [(String, String, HKQuantityTypeIdentifier)] = [
            ("Steps", "figure.walk", .stepCount),
            ("Heart Rate", "heart.fill", .heartRate),
            ("HRV", "waveform.path.ecg", .heartRateVariabilitySDNN),
            ("Active Energy", "flame.fill", .activeEnergyBurned),
        ]
        permissionStatuses = identifiers.compactMap { name, icon, id in
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
            let status = store.authorizationStatus(for: type)
            return HealthPermission(name: name, iconName: icon, status: status)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let status = store.authorizationStatus(for: sleepType)
            permissionStatuses.append(HealthPermission(name: "Sleep", iconName: "moon.fill", status: status))
        }
    }
}

// MARK: - Permission Model

private struct HealthPermission: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let status: HKAuthorizationStatus

    var statusLabel: String {
        switch status {
        case .sharingAuthorized:  return "Authorized"
        case .sharingDenied:      return "Denied"
        case .notDetermined:      return "Not Set"
        @unknown default:         return "Unknown"
        }
    }

    var statusColor: Color {
        switch status {
        case .sharingAuthorized:  return .green
        case .sharingDenied:      return .red
        case .notDetermined:      return .secondary
        @unknown default:         return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
