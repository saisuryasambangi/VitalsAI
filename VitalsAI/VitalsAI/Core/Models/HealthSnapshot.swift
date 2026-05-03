import Foundation

struct HealthSnapshot: Sendable {
    let steps: Int
    let restingHeartRate: Double?
    let hrvSDNN: Double?
    let sleepHours: Double
    let activeEnergyKcal: Double
    let date: Date

    static func makeEmpty() -> HealthSnapshot {
        HealthSnapshot(
            steps: 0,
            restingHeartRate: nil,
            hrvSDNN: nil,
            sleepHours: 0,
            activeEnergyKcal: 0,
            date: Date()
        )
    }

    var hasSignificantData: Bool {
        var count = 0
        if steps > 0 { count += 1 }
        if let hr = restingHeartRate, hr > 0 { count += 1 }
        if let hrv = hrvSDNN, hrv > 0 { count += 1 }
        if sleepHours > 0 { count += 1 }
        if activeEnergyKcal > 0 { count += 1 }
        return count >= 2
    }
}
