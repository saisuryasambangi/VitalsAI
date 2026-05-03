import XCTest
@testable import VitalsAI

final class BenchmarkServiceTests: XCTestCase {
    private let service = BenchmarkService()

    func testValidLookupReturnsNonNil() {
        let result = service.lookup(metric: "resting_heart_rate", ageGroup: "25-34", biologicalSex: "male")
        XCTAssertNotNil(result, "Expected non-nil for known metric and age group")
    }

    func testInvalidMetricReturnsNil() {
        let result = service.lookup(metric: "invalid_metric_xyz", ageGroup: "25-34", biologicalSex: "male")
        XCTAssertNil(result, "Expected nil for unknown metric")
    }

    func testInvalidAgeGroupReturnsNil() {
        let result = service.lookup(metric: "resting_heart_rate", ageGroup: "999+", biologicalSex: "male")
        XCTAssertNil(result, "Expected nil for unknown age group")
    }

    func testAllMetricsHaveSensibleRanges() {
        let metrics = ["resting_heart_rate", "hrv_sdnn", "steps_daily", "sleep_hours"]
        let ageGroups = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]

        for metric in metrics {
            for ageGroup in ageGroups {
                guard let range = service.lookup(metric: metric, ageGroup: ageGroup, biologicalSex: "male") else {
                    XCTFail("Missing benchmark for \(metric) / \(ageGroup)")
                    continue
                }
                XCTAssertLessThan(range.low, range.high,
                    "\(metric) \(ageGroup): low (\(range.low)) must be less than high (\(range.high))")
                XCTAssertGreaterThanOrEqual(range.low, 0,
                    "\(metric) \(ageGroup): low must be non-negative")
            }
        }
    }

    func testHRVRangesDecreaseWithAge() {
        // Older age groups should have lower (or equal) HRV upper bounds
        let young = service.lookup(metric: "hrv_sdnn", ageGroup: "18-24", biologicalSex: "male")
        let old   = service.lookup(metric: "hrv_sdnn", ageGroup: "65+",   biologicalSex: "male")
        XCTAssertNotNil(young)
        XCTAssertNotNil(old)
        if let young, let old {
            XCTAssertGreaterThan(young.high, old.high,
                "Younger adults should have higher HRV ceiling than older adults")
        }
    }
}
