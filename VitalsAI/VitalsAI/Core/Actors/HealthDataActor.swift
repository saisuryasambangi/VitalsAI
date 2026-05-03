@preconcurrency import HealthKit
import Foundation

actor HealthDataActor {
    private let healthStore = HKHealthStore()

    static var readPermissions: Set<HKSampleType> {
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .stepCount,
            .activeEnergyBurned
        ]
        var types = Set<HKSampleType>()
        for id in quantityIdentifiers {
            if let t = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthDataError.notAvailable
        }
        let readTypes: Set<HKObjectType> = Set(HealthDataActor.readPermissions.map { $0 as HKObjectType })
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchWeeklySnapshot() async throws -> HealthSnapshot {
        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: end) else {
            throw HealthDataError.queryFailed("Could not compute start date")
        }

        async let hrSamples = fetchQuantitySamples(
            typeIdentifier: .heartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            startDate: start, endDate: end
        )
        async let hrvSamples = fetchQuantitySamples(
            typeIdentifier: .heartRateVariabilitySDNN,
            unit: HKUnit.secondUnit(with: .milli),
            startDate: start, endDate: end
        )
        async let stepSamples = fetchQuantitySamples(
            typeIdentifier: .stepCount,
            unit: .count(),
            startDate: start, endDate: end
        )
        async let energySamples = fetchQuantitySamples(
            typeIdentifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            startDate: start, endDate: end
        )
        async let sleepTotal = fetchSleepHours(startDate: start, endDate: end)

        let (hr, hrv, steps, energy, sleep) = try await (hrSamples, hrvSamples, stepSamples, energySamples, sleepTotal)

        let avgHR = hr.isEmpty ? nil : hr.reduce(0, +) / Double(hr.count)
        let avgHRV = hrv.isEmpty ? nil : hrv.reduce(0, +) / Double(hrv.count)

        return HealthSnapshot(
            steps: Int(steps.reduce(0, +)),
            restingHeartRate: avgHR,
            hrvSDNN: avgHRV,
            sleepHours: sleep,
            activeEnergyKcal: energy.reduce(0, +),
            date: end
        )
    }

    private func fetchQuantitySamples(
        typeIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> [Double] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            throw HealthDataError.queryFailed("Unknown type: \(typeIdentifier.rawValue)")
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let store = healthStore

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                let values = (samples as? [HKQuantitySample])?.map {
                    $0.quantity.doubleValue(for: unit)
                } ?? []
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }

    private func fetchSleepHours(startDate: Date, endDate: Date) async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthDataError.queryFailed("Sleep analysis type unavailable")
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let store = healthStore

        // Process samples and return only a Sendable Double to satisfy Swift 6 strict concurrency
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthDataError.queryFailed(error.localizedDescription))
                    return
                }
                let asleepStages: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let totalSeconds = (samples as? [HKCategorySample])?
                    .filter { asleepStages.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0.0
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            store.execute(query)
        }
    }
}

enum HealthDataError: Error, LocalizedError, Sendable {
    case notAvailable
    case authorizationDenied
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .authorizationDenied:
            return "Authorization to access health data was denied."
        case .queryFailed(let message):
            return "Health data query failed: \(message)"
        }
    }
}
