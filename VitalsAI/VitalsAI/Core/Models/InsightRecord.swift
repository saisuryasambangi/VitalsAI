import Foundation
import SwiftData

@Model
final class InsightRecord {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var summary: String = ""
    var trend: String = HealthTrend.stable.rawValue
    var recommendations: [String] = [String]()
    var providerUsed: String = "anthropic"
    var weekStartDate: Date = Date()

    // Snapshot of the week's metrics — used for week-over-week trend arrows.
    // 0 means "no data" for that field (mirrors HealthSnapshot optionals).
    var snapshotDailySteps: Int = 0
    var snapshotRestingHR: Double = 0
    var snapshotHRVSDNN: Double = 0
    var snapshotNightlySleep: Double = 0
    var snapshotDailyEnergy: Double = 0

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        summary: String = "",
        trend: String = HealthTrend.stable.rawValue,
        recommendations: [String] = [],
        providerUsed: String = "anthropic",
        weekStartDate: Date = Date(),
        snapshotDailySteps: Int = 0,
        snapshotRestingHR: Double = 0,
        snapshotHRVSDNN: Double = 0,
        snapshotNightlySleep: Double = 0,
        snapshotDailyEnergy: Double = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.summary = summary
        self.trend = trend
        self.recommendations = recommendations
        self.providerUsed = providerUsed
        self.weekStartDate = weekStartDate
        self.snapshotDailySteps = snapshotDailySteps
        self.snapshotRestingHR = snapshotRestingHR
        self.snapshotHRVSDNN = snapshotHRVSDNN
        self.snapshotNightlySleep = snapshotNightlySleep
        self.snapshotDailyEnergy = snapshotDailyEnergy
    }
}
