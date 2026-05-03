@preconcurrency import HealthKit

extension HKQuantityTypeIdentifier {
    var displayName: String {
        if self == .heartRate { return "Heart Rate" }
        if self == .heartRateVariabilitySDNN { return "HRV (SDNN)" }
        if self == .stepCount { return "Steps" }
        if self == .activeEnergyBurned { return "Active Energy" }
        if self == .restingHeartRate { return "Resting Heart Rate" }
        return rawValue
    }

    var defaultUnit: HKUnit {
        if self == .heartRate { return HKUnit.count().unitDivided(by: .minute()) }
        if self == .heartRateVariabilitySDNN { return HKUnit.secondUnit(with: .milli) }
        if self == .stepCount { return .count() }
        if self == .activeEnergyBurned { return .kilocalorie() }
        if self == .restingHeartRate { return HKUnit.count().unitDivided(by: .minute()) }
        return .count()
    }
}
