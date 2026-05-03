import XCTest
@testable import VitalsAI

final class LLMModelsTests: XCTestCase {

    // MARK: HealthTrend

    func testHealthTrendRawValuesAreStable() {
        XCTAssertEqual(HealthTrend.improving.rawValue, "improving")
        XCTAssertEqual(HealthTrend.stable.rawValue,    "stable")
        XCTAssertEqual(HealthTrend.declining.rawValue, "declining")
    }

    func testHealthTrendDisplayLabels() {
        XCTAssertEqual(HealthTrend.improving.displayLabel, "Improving")
        XCTAssertEqual(HealthTrend.stable.displayLabel,    "Stable")
        XCTAssertEqual(HealthTrend.declining.displayLabel, "Declining")
    }

    func testHealthTrendColorStrings() {
        XCTAssertEqual(HealthTrend.improving.color, "green")
        XCTAssertEqual(HealthTrend.stable.color,    "yellow")
        XCTAssertEqual(HealthTrend.declining.color, "red")
    }

    func testHealthTrendRoundTrip() {
        for trend in HealthTrend.allCases {
            let raw = trend.rawValue
            XCTAssertEqual(HealthTrend(rawValue: raw), trend,
                "Round-trip failed for \(raw)")
        }
    }

    // MARK: LLMProviderType

    func testLLMProviderTypeHasTwoCases() {
        XCTAssertEqual(LLMProviderType.allCases.count, 2)
    }

    func testLLMProviderTypeRawValues() {
        XCTAssertEqual(LLMProviderType.anthropic.rawValue, "anthropic")
        XCTAssertEqual(LLMProviderType.onDevice.rawValue,  "onDevice")
    }

    func testAnthropicIsAvailable() {
        XCTAssertTrue(LLMProviderType.anthropic.isAvailable)
    }

    func testOnDeviceIsUnavailable() {
        XCTAssertFalse(LLMProviderType.onDevice.isAvailable,
            "On-device provider requires iOS 26 — should be unavailable on iOS 18")
    }

    // MARK: LLMError

    func testLLMErrorDescriptions() {
        XCTAssertNotNil(LLMError.missingAPIKey.errorDescription)
        XCTAssertNotNil(LLMError.unavailable("test").errorDescription)
        XCTAssertNotNil(LLMError.apiError(statusCode: 429, message: "rate limit").errorDescription)
        XCTAssertNotNil(LLMError.decodingFailed("bad json").errorDescription)
    }
}
