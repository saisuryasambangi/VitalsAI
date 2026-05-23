import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct VitalsEntry: TimelineEntry {
    let date: Date
    let trend: String?
    let weekOf: Date?
    let summary: String?
}

// MARK: - Provider

struct VitalsProvider: TimelineProvider {

    func placeholder(in context: Context) -> VitalsEntry {
        VitalsEntry(date: .now, trend: "improving", weekOf: .now, summary: "Your health looks great this week.")
    }

    func getSnapshot(in context: Context, completion: @escaping (VitalsEntry) -> Void) {
        completion(latestEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VitalsEntry>) -> Void) {
        let entry = latestEntry()
        // Refresh once a day
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func latestEntry() -> VitalsEntry {
        // Shared SwiftData store via App Group
        guard
            let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.saisuryasambangi.VitalsAI"),
            let container = try? ModelContainer(
                for: InsightRecord.self,
                configurations: ModelConfiguration(url: groupURL.appendingPathComponent("VitalsAI.store"))
            )
        else {
            return VitalsEntry(date: .now, trend: nil, weekOf: nil, summary: nil)
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<InsightRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let records = try? context.fetch(descriptor)
        let latest = records?.first

        return VitalsEntry(
            date: .now,
            trend: latest?.trend,
            weekOf: latest?.weekStartDate,
            summary: latest?.summary
        )
    }
}

// MARK: - Widget View

struct VitalsWidgetView: View {
    let entry: VitalsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let trend = entry.trend, let weekOf = entry.weekOf {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(.pink)
                    Text("VitalsAI")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Spacer()

                trendBadge(trend)

                Text("Week of \(weekOf.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if family != .systemSmall, let summary = entry.summary {
                    Text(summary)
                        .font(.caption)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                }
            }
            .padding()
            .containerBackground(.background, for: .widget)
        } else {
            noDataView
        }
    }

    private func trendBadge(_ trend: String) -> some View {
        let color: Color = switch trend {
        case "improving": .green
        case "declining": .red
        default:          .yellow
        }
        let icon = trend == "improving" ? "arrow.up" : trend == "declining" ? "arrow.down" : "minus"
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.caption.bold())
            Text(trend.capitalized).font(.subheadline.bold())
        }
        .foregroundStyle(color)
    }

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.text.square")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget Definition

struct VitalsAIWidget: Widget {
    let kind = "VitalsAIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VitalsProvider()) { entry in
            VitalsWidgetView(entry: entry)
        }
        .configurationDisplayName("VitalsAI")
        .description("Your latest weekly health insight at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
