import Foundation

struct UserProfile: Codable, Sendable {
    var age: Int = 30
    var biologicalSex: String = "unknown"

    enum BiologicalSex: String, CaseIterable, Sendable {
        case male, female, other, unknown

        var displayName: String { rawValue.capitalized }
    }
}
