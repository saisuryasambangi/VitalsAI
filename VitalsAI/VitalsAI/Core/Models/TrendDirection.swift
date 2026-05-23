import SwiftUI

enum TrendDirection: Sendable {
    case up, down, neutral

    var color: Color {
        switch self {
        case .up:      return .green
        case .down:    return .red
        case .neutral: return .secondary
        }
    }

    var iconName: String {
        switch self {
        case .up:      return "arrow.up"
        case .down:    return "arrow.down"
        case .neutral: return "minus"
        }
    }
}
