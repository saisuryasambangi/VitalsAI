import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \InsightRecord.createdAt, order: .reverse) private var records: [InsightRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(records) { record in
                        HistoryRow(record: record)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !records.isEmpty {
                EditButton()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.title3.bold())
            Text("Tap \"Analyze with AI\" on the dashboard to generate your first weekly summary.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

private struct HistoryRow: View {
    let record: InsightRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(weekLabel)
                    .font(.subheadline.bold())
                Spacer()
                TrendPill(rawValue: record.trend)
            }
            if let firstRec = record.recommendations.first, !firstRec.isEmpty {
                Text(firstRec)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(record.providerUsed == "anthropic" ? "Anthropic Claude" : record.providerUsed)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: record.weekStartDate))"
    }
}

private struct TrendPill: View {
    let rawValue: String

    private var trend: HealthTrend? { HealthTrend(rawValue: rawValue) }

    var body: some View {
        let label = trend?.displayLabel ?? rawValue.capitalized
        let color: Color = switch trend {
        case .improving: .green
        case .stable:    .yellow
        case .declining: .red
        case .none:      .secondary
        }

        Text(label)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: InsightRecord.self, inMemory: true)
}
