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

struct MetricCardView: View {
    let title: String
    let value: String
    let unit: String
    let iconName: String
    let trendDirection: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(trendDirection.color)
                    .font(.title3)
                Spacer()
                Image(systemName: trendDirection.iconName)
                    .foregroundStyle(trendDirection.color)
                    .font(.caption)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text("\(title) · \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

#Preview {
    HStack {
        MetricCardView(title: "Steps", value: "8,412", unit: "steps", iconName: "figure.walk", trendDirection: .up)
        MetricCardView(title: "Heart Rate", value: "62", unit: "bpm", iconName: "heart.fill", trendDirection: .neutral)
    }
    .padding()
}
