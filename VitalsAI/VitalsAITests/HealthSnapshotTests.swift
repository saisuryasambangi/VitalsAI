import XCTest
@testable import VitalsAI

final class HealthSnapshotTests: XCTestCase {

    func testMakeEmptyReturnsAllZeroes() {
        let empty = HealthSnapshot.makeEmpty()
        XCTAssertEqual(empty.steps, 0)
        XCTAssertNil(empty.restingHeartRate)
        XCTAssertNil(empty.hrvSDNN)
        XCTAssertEqual(empty.sleepHours, 0)
        XCTAssertEqual(empty.activeEnergyKcal, 0)
    }

    func testEmptySnapshotHasNoSignificantData() {
        let empty = HealthSnapshot.makeEmpty()
        XCTAssertFalse(empty.hasSignificantData,
            "Empty snapshot should not have significant data")
    }

    func testSnapshotWithOneMetricHasNoSignificantData() {
        let snapshot = HealthSnapshot(
            steps: 8000,
            restingHeartRate: nil,
            hrvSDNN: nil,
            sleepHours: 0,
            activeEnergyKcal: 0,
            date: Date()
        )
        XCTAssertFalse(snapshot.hasSignificantData,
            "Only one non-zero field should not reach the threshold of 2")
    }

    func testSnapshotWithStepsAndHRHasSignificantData() {
        let snapshot = HealthSnapshot(
            steps: 7500,
            restingHeartRate: 65,
            hrvSDNN: nil,
            sleepHours: 0,
            activeEnergyKcal: 0,
            date: Date()
        )
        XCTAssertTrue(snapshot.hasSignificantData,
            "steps > 0 and HR > 0 should give hasSignificantData = true")
    }

    func testSnapshotWithAllMetricsHasSignificantData() {
        let snapshot = HealthSnapshot(
            steps: 9000,
            restingHeartRate: 62,
            hrvSDNN: 55,
            sleepHours: 7.5,
            activeEnergyKcal: 480,
            date: Date()
        )
        XCTAssertTrue(snapshot.hasSignificantData)
    }

    func testSnapshotWithSleepOnlyHasNoSignificantData() {
        let snapshot = HealthSnapshot(
            steps: 0,
            restingHeartRate: nil,
            hrvSDNN: nil,
            sleepHours: 8.0,
            activeEnergyKcal: 0,
            date: Date()
        )
        XCTAssertFalse(snapshot.hasSignificantData,
            "Single non-zero field (sleep only) should not reach threshold")
    }
}
