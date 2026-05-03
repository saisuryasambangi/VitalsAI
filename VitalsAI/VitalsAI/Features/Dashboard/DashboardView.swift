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
                } else {
                    // Kick off generation immediately; show streaming UI while waiting
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCardView(
                title: "Steps",
                value: snap.steps.formatted(),
                unit: "steps",
                iconName: "figure.walk",
                trendDirection: .neutral
            )
            MetricCardView(
                title: "Heart Rate",
                value: snap.restingHeartRate.map { String(format: "%.0f", $0) } ?? "–",
                unit: "bpm",
                iconName: "heart.fill",
                trendDirection: .neutral
            )
            MetricCardView(
                title: "HRV",
                value: snap.hrvSDNN.map { String(format: "%.1f", $0) } ?? "–",
                unit: "ms",
                iconName: "waveform.path.ecg",
                trendDirection: .neutral
            )
            MetricCardView(
                title: "Sleep",
                value: String(format: "%.1f", snap.sleepHours),
                unit: "hrs",
                iconName: "moon.fill",
                trendDirection: .neutral
            )
        }
    }

    private var analyzeButton: some View {
        Button {
            insightViewModel = InsightViewModel(
                llmService: LLMServiceFactory.make(providerType: viewModel.resolvedProvider),
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
