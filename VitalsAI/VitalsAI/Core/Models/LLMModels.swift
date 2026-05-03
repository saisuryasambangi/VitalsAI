import Foundation

// MARK: - HealthInsight

struct HealthInsight: Codable, Sendable, Equatable {
    let summary: String
    let overallTrend: HealthTrend
    let recommendations: [String]
    let standoutMetric: String
    let confidenceScore: Double
}

// MARK: - HealthTrend

enum HealthTrend: String, Codable, Sendable, CaseIterable {
    case improving, stable, declining

    var displayLabel: String {
        switch self {
        case .improving: return "Improving"
        case .stable:    return "Stable"
        case .declining: return "Declining"
        }
    }

    // Returns semantic color name strings — caller maps to SwiftUI Color
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable:    return "yellow"
        case .declining: return "red"
        }
    }
}

// MARK: - LLMProviderType

enum LLMProviderType: String, CaseIterable, Sendable {
    case onDevice   // placeholder — not implemented until Xcode 26
    case anthropic

    var displayName: String {
        switch self {
        case .onDevice:  return "On-Device (Coming Soon)"
        case .anthropic: return "Anthropic Claude"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .onDevice:  return false   // will become #available(iOS 26, *) check later
        case .anthropic: return true
        }
    }
}

// MARK: - LLMError

enum LLMError: Error, LocalizedError, Sendable {
    case unavailable(String)
    case generationFailed(String)
    case apiError(statusCode: Int, message: String)
    case decodingFailed(String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return "LLM unavailable: \(reason)"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .decodingFailed(let reason):
            return "Could not parse response: \(reason)"
        case .missingAPIKey:
            return "Anthropic API key not configured. Add ANTHROPIC_API_KEY to your scheme environment variables."
        }
    }
}
