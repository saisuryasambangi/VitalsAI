import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Query(sort: \InsightRecord.createdAt, order: .reverse) private var insights: [InsightRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var showInsightSheet = false
    @State private var insightViewModel: InsightViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting header
                headerView

                // Error banner
                if let errorMessage = viewModel.healthError {
                    ErrorBannerView(message: errorMessage) {
                        Task { await viewModel.authorizeAndFetch() }
                    }
                    .animation(.easeInOut, value: viewModel.healthError)
                }

                if !viewModel.isAuthorized && !viewModel.isLoadingHealth {
                    authorizationPrompt
                }

                if viewModel.isLoadingHealth {
                    ProgressView("Loading health data…")
                        .padding()
                }

                if let snap = viewModel.snapshot {
                    metricsGrid(snap)
                }

                if let latest = insights.first {
                    Text("Last analyzed: \(latest.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                analyzeButton
            }
            .padding()
        }
        .refreshable {
            await viewModel.authorizeAndFetch()
        }
        .navigationTitle("VitalsAI")
        .task {
            await viewModel.authorizeAndFetch()
        }
        .sheet(isPresented: $showInsightSheet) {
            insightSheet
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Here's your week")
                    .font(.title2.bold())
            }
            Spacer()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }

    // MARK: - Insight Sheet

    @ViewBuilder
    private var insightSheet: some View {
        NavigationStack {
            if let vm = insightViewModel {
                if vm.isGenerating {
                    StreamingInsightView()
                        .navigationTitle("Your Weekly Insight")
                        .navigationBarTitleDisplayMode(.inline)
                } else if vm.currentInsight != nil {
                    InsightDetailView(viewModel: vm)
                } else if let errorMessage = vm.error {
                    insightErrorView(message: errorMessage, vm: vm)
                        .navigationTitle("Your Weekly Insight")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    StreamingInsightView()
                        .navigationTitle("Your Weekly Insight")
                        .navigationBarTitleDisplayMode(.inline)
                        .task {
                            if let snapshot = viewModel.snapshot {
                                await vm.generateInsight(
                                    from: snapshot,
                                    userAge: viewModel.userAge,
                                    biologicalSex: viewModel.userSex
                                )
                            }
                        }
                }
            }
        }
    }

    private func insightErrorView(message: String, vm: InsightViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                Task {
                    if let snapshot = viewModel.snapshot {
                        await vm.generateInsight(
                            from: snapshot,
                            userAge: viewModel.userAge,
                            biologicalSex: viewModel.userSex
                        )
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Dismiss") { showInsightSheet = false }
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Subviews

    private var authorizationPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.largeTitle)
                .foregroundStyle(.pink)
            Text("Connect to Health")
                .font(.headline)
            Text("Grant access so VitalsAI can read your weekly metrics.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Connect to HealthKit") {
                Task { await viewModel.authorizeAndFetch() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func metricsGrid(_ snap: HealthSnapshot) -> some View {
        let benchmarks = BenchmarkService()
        let age = viewModel.userAge
        let sex = viewModel.userSex
        let dailySteps = Double(snap.steps) / 7.0
        let nightlySleep = snap.sleepHours / 7.0
        let prev = insights.first   // most recently saved record for week-over-week

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCardView(
                title: "Steps",
                value: (snap.steps / 7).formatted(),
                unit: "avg/day",
                iconName: "figure.walk",
                trendDirection: weekOverWeek(
                    current: dailySteps,
                    previous: prev.map { Double($0.snapshotDailySteps) },
                    fallback: benchmarks.compare(metric: "steps_daily", value: dailySteps, age: age, biologicalSex: sex)
                )
            )
            // Resting HR: higher isn't better, so always use benchmark comparison
            MetricCardView(
                title: "Resting HR",
                value: snap.restingHeartRate.map { String(format: "%.0f", $0) } ?? "–",
                unit: "bpm",
                iconName: "heart.fill",
                trendDirection: snap.restingHeartRate.map {
                    benchmarks.compare(metric: "resting_heart_rate", value: $0, age: age, biologicalSex: sex)
                } ?? .neutral
            )
            MetricCardView(
                title: "HRV",
                value: snap.hrvSDNN.map { String(format: "%.1f", $0) } ?? "–",
                unit: "ms",
                iconName: "waveform.path.ecg",
                trendDirection: snap.hrvSDNN.map { hrv in
                    weekOverWeek(
                        current: hrv,
                        previous: prev.map { $0.snapshotHRVSDNN },
                        fallback: benchmarks.compare(metric: "hrv_sdnn", value: hrv, age: age, biologicalSex: sex)
                    )
                } ?? .neutral
            )
            MetricCardView(
                title: "Sleep",
                value: String(format: "%.1f", nightlySleep),
                unit: "avg/night",
                iconName: "moon.fill",
                trendDirection: weekOverWeek(
                    current: nightlySleep,
                    previous: prev.map { $0.snapshotNightlySleep },
                    fallback: benchmarks.compare(metric: "sleep_hours", value: nightlySleep, age: age, biologicalSex: sex)
                )
            )
        }
    }

    /// Compares current value to previous week's value.
    /// Returns `.up` / `.down` for >5 % change, `.neutral` within that band.
    /// Falls back to benchmark comparison when no previous record exists.
    private func weekOverWeek(current: Double, previous: Double?, fallback: TrendDirection) -> TrendDirection {
        guard let prev = previous, prev > 0 else { return fallback }
        let pct = (current - prev) / prev
        if pct >  0.05 { return .up }
        if pct < -0.05 { return .down }
        return .neutral
    }

    private var analyzeButton: some View {
        Button {
            insightViewModel = InsightViewModel(
                llmService: LLMServiceFactory.make(providerType: viewModel.resolvedProvider),
                providerType: viewModel.resolvedProvider,
                modelContext: modelContext
            )
            showInsightSheet = true
        } label: {
            Label("Analyze with AI", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.snapshot == nil || viewModel.isLoadingHealth)
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: InsightRecord.self, inMemory: true)
}
