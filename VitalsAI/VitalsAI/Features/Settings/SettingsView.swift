import SwiftUI
@preconcurrency import HealthKit
import UIKit

struct SettingsView: View {
    @AppStorage("preferred_provider") private var preferredProvider: String = LLMProviderType.anthropic.rawValue
    @AppStorage("user_age") private var userAge: Int = 30
    @AppStorage("user_sex") private var userSex: String = "unknown"
    @State private var permissionStatuses: [HealthPermission] = []

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
        }
    }

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
