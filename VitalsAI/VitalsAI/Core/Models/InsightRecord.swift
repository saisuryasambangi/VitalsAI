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

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        summary: String = "",
        trend: String = HealthTrend.stable.rawValue,
        recommendations: [String] = [],
        providerUsed: String = "anthropic",
        weekStartDate: Date = Date()
    ) {
        self.id = id
        self.createdAt = createdAt
        self.summary = summary
        self.trend = trend
        self.recommendations = recommendations
        self.providerUsed = providerUsed
        self.weekStartDate = weekStartDate
    }
}
