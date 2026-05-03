import Foundation
import SwiftData

@Model
final class InsightRecord {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var summary: String = ""
    var trend: String = TrendType.neutral.rawValue
    var recommendations: [String] = [String]()
    var providerUsed: String = "on-device"
    var weekStartDate: Date = Date()

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        summary: String = "",
        trend: String = TrendType.neutral.rawValue,
        recommendations: [String] = [],
        providerUsed: String = "on-device",
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

enum TrendType: String, Sendable, CaseIterable {
    case improving
    case declining
    case neutral
    case insufficient
}
