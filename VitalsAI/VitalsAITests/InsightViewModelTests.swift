import XCTest
import SwiftData
@testable import VitalsAI

actor MockLLMService: LLMService {
    let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func generateInsight(
        from snapshot: HealthSnapshot,
        userAge: Int,
        biologicalSex: String
    ) async throws -> HealthInsight {
        if shouldFail {
            throw LLMError.generationFailed("mock")
        }
        return HealthInsight(
            summary: "Test summary",
            overallTrend: .stable,
            recommendations: ["Rec 1", "Rec 2"],
            standoutMetric: "Steps",
            confidenceScore: 0.9
        )
    }
}

@MainActor
final class InsightViewModelTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: InsightRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func test_generateInsight_success_setsCurrentInsight() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockLLMService(shouldFail: false)
        let vm = InsightViewModel(llmService: mock, providerType: .anthropic, modelContext: context)

        await vm.generateInsight(from: .makeEmpty(), userAge: 30, biologicalSex: "male")

        XCTAssertNotNil(vm.currentInsight)
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.isGenerating)
    }

    func test_generateInsight_failure_setsError() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockLLMService(shouldFail: true)
        let vm = InsightViewModel(llmService: mock, providerType: .anthropic, modelContext: context)

        await vm.generateInsight(from: .makeEmpty(), userAge: 30, biologicalSex: "male")

        XCTAssertNotNil(vm.error)
        XCTAssertNil(vm.currentInsight)
    }

    func test_generateInsight_isGenerating_falseAfterCompletion() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockLLMService(shouldFail: false)
        let vm = InsightViewModel(llmService: mock, providerType: .anthropic, modelContext: context)

        await vm.generateInsight(from: .makeEmpty(), userAge: 30, biologicalSex: "male")

        XCTAssertFalse(vm.isGenerating)
    }

    func test_saveCurrentInsight_idempotent() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockLLMService(shouldFail: false)
        let vm = InsightViewModel(llmService: mock, providerType: .anthropic, modelContext: context)

        await vm.generateInsight(from: .makeEmpty(), userAge: 30, biologicalSex: "male")

        vm.saveCurrentInsight()
        vm.saveCurrentInsight()

        XCTAssertTrue(vm.isSaved)

        let descriptor = FetchDescriptor<InsightRecord>()
        let records = try context.fetch(descriptor)
        XCTAssertEqual(records.count, 1, "saveCurrentInsight() called twice must produce exactly one record")
    }
}
