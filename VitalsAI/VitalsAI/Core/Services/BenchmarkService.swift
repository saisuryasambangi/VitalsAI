import Foundation

final class BenchmarkService: Sendable {
    struct BenchmarkRange: Sendable {
        let metricName: String
        let low: Double
        let high: Double
        let unit: String
        let source: String
    }

    // Keyed by [metricName: [ageGroup: BenchmarkRange]]
    private static let data: [String: [String: BenchmarkRange]] = {
        let heartRate: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association"),
            "25-34": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association"),
            "35-44": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association"),
            "45-54": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association"),
            "55-64": BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association"),
            "65+":   BenchmarkRange(metricName: "Resting Heart Rate", low: 60, high: 100, unit: "bpm", source: "American Heart Association"),
        ]

        // Firstbeat Technologies / WHOOP reference values (SDNN, ms)
        let hrvSDNN: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "HRV (SDNN)", low: 60, high: 120, unit: "ms", source: "Firstbeat Technologies"),
            "25-34": BenchmarkRange(metricName: "HRV (SDNN)", low: 50, high: 100, unit: "ms", source: "Firstbeat Technologies"),
            "35-44": BenchmarkRange(metricName: "HRV (SDNN)", low: 40, high:  85, unit: "ms", source: "Firstbeat Technologies"),
            "45-54": BenchmarkRange(metricName: "HRV (SDNN)", low: 35, high:  75, unit: "ms", source: "Firstbeat Technologies"),
            "55-64": BenchmarkRange(metricName: "HRV (SDNN)", low: 25, high:  65, unit: "ms", source: "Firstbeat Technologies"),
            "65+":   BenchmarkRange(metricName: "HRV (SDNN)", low: 20, high:  55, unit: "ms", source: "Firstbeat Technologies"),
        ]

        // WHO Global Physical Activity Guidelines
        let steps: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines"),
            "25-34": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines"),
            "35-44": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines"),
            "45-54": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines"),
            "55-64": BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines"),
            "65+":   BenchmarkRange(metricName: "Daily Steps", low: 7000, high: 10000, unit: "steps", source: "WHO Global Physical Activity Guidelines"),
        ]

        // National Sleep Foundation guidelines
        let sleep: [String: BenchmarkRange] = [
            "18-24": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation"),
            "25-34": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation"),
            "35-44": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation"),
            "45-54": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation"),
            "55-64": BenchmarkRange(metricName: "Sleep", low: 7, high: 9, unit: "hrs", source: "National Sleep Foundation"),
            "65+":   BenchmarkRange(metricName: "Sleep", low: 7, high: 8, unit: "hrs", source: "National Sleep Foundation"),
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
}
