import Foundation

final class BenchmarkService: Sendable {
    struct BenchmarkRange: Sendable {
        let metricName: String
        let low: Double
        let high: Double
        let unit: String
        let source: String
        let higherIsBetter: Bool
    }

    // Keyed by [metricName: [ageGroup: BenchmarkRange]]
    private static let data: [String: [String: BenchmarkRange]] = {
        let heartRate: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association", higherIsBetter: false),
            "25-34": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association", higherIsBetter: false),
            "35-44": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association", higherIsBetter: false),
            "45-54": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association", higherIsBetter: false),
            "55-64": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association", higherIsBetter: false),
            "65+":   BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association", higherIsBetter: false),
        ]

        // Firstbeat Technologies / WHOOP reference values (SDNN, ms)
        let hrvSDNN: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "HRV (SDNN)", low: 60, high: 120, unit: "ms", source: "Firstbeat Technologies", higherIsBetter: true),
            "25-34": BenchmarkRange(metricName: "HRV (SDNN)", low: 50, high: 100, unit: "ms", source: "Firstbeat Technologies", higherIsBetter: true),
            "35-44": BenchmarkRange(metricName: "HRV (SDNN)", low: 40, high:  85, unit: "ms", source: "Firstbeat Technologies", higherIsBetter: true),
            "45-54": BenchmarkRange(metricName: "HRV (SDNN)", low: 35, high:  75, unit: "ms", source: "Firstbeat Technologies", higherIsBetter: true),
            "55-64": BenchmarkRange(metricName: "HRV (SDNN)", low: 25, high:  65, unit: "ms", source: "Firstbeat Technologies", higherIsBetter: true),
            "65+":   BenchmarkRange(metricName: "HRV (SDNN)", low: 20, high:  55, unit: "ms", source: "Firstbeat Technologies", higherIsBetter: true),
        ]

        // WHO Global Physical Activity Guidelines
        let steps: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines", higherIsBetter: true),
            "25-34": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines", higherIsBetter: true),
            "35-44": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines", higherIsBetter: true),
            "45-54": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines", higherIsBetter: true),
            "55-64": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines", higherIsBetter: true),
            "65+":   BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines", higherIsBetter: true),
        ]

        // National Sleep Foundation guidelines
        let sleep: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation", higherIsBetter: false),
            "25-34": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation", higherIsBetter: false),
            "35-44": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation", higherIsBetter: false),
            "45-54": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation", higherIsBetter: false),
            "55-64": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation", higherIsBetter: false),
            "65+":   BenchmarkRange(metricName: "Sleep", low: 7, high: 8, unit: "hrs", source: "National Sleep Foundation", higherIsBetter: false),
        ]

        return [
            "resting_heart_rate": heartRate,
            "hrv_sdnn": hrvSDNN,
            "steps_daily": steps,
            "sleep_hours": sleep,
        ]
    }()

    func lookup(metric: String, ageGroup: String, biologicalSex: String) -> BenchmarkRange? {
        BenchmarkService.data[metric]?[ageGroup]
    }

    func compare(metric: String, value: Double, age: Int, biologicalSex: String) -> TrendDirection {
        let group = BenchmarkService.ageGroup(for: age)
        guard let range = lookup(metric: metric, ageGroup: group, biologicalSex: biologicalSex) else {
            return .neutral
        }
        if value > range.high { return range.higherIsBetter ? .up : .down }
        if value < range.low  { return range.higherIsBetter ? .down : .up }
        return .neutral
    }

    static func ageGroup(for age: Int) -> String {
        switch age {
        case ..<25:   return "18-24"
        case 25..<35: return "25-34"
        case 35..<45: return "35-44"
        case 45..<55: return "45-54"
        case 55..<65: return "55-64"
        default:      return "65+"
        }
    }
}
