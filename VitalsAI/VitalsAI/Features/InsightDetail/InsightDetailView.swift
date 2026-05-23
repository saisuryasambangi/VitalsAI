import SwiftUI

struct InsightDetailView: View {
    let viewModel: InsightViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let insight = viewModel.currentInsight {
                content(insight)
            } else {
                ContentUnavailableView("No Insight", systemImage: "brain.head.profile")
            }
        }
        .navigationTitle("Your Weekly Insight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func content(_ insight: HealthInsight) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Trend badge
                trendBadge(insight.overallTrend)

                // Summary
                Text(insight.summary)
                    .font(.body)
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)

                Divider()

                // Standout metric
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Standout this week")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(insight.standoutMetric)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Divider()

                // Recommendations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommendations")
                        .font(.headline)

                    ForEach(insight.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.body)
                                .padding(.top, 2)
                            Text(rec)
                                .font(.subheadline)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Low-confidence note (only shown when data is sparse)
                if insight.confidenceScore < 0.7 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Limited data — connect more health sources for a richer analysis.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                // Save button
                Button {
                    viewModel.saveCurrentInsight()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
                } label: {
                    Label(
                        viewModel.isSaved ? "Saved!" : "Save to History",
                        systemImage: viewModel.isSaved ? "checkmark" : "square.and.arrow.down"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSaved)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isSaved)
                .padding(.top, 8)
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func trendBadge(_ trend: HealthTrend) -> some View {
        let color: Color = switch trend {
        case .improving: .green
        case .stable:    .yellow
        case .declining: .red
        }

        HStack(spacing: 6) {
            Image(systemName: trend == .improving ? "arrow.up" : trend == .declining ? "arrow.down" : "minus")
                .font(.caption.bold())
            Text(trend.displayLabel)
                .font(.subheadline.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(color.opacity(0.15), in: Capsule())
    }
}
