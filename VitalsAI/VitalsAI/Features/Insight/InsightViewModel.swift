import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class InsightViewModel {
    var currentInsight: HealthInsight?
    var isGenerating = false
    var error: String?
    var providerUsed: LLMProviderType = .anthropic
    var isSaved = false

    private let llmService: any LLMService
    private let modelContext: ModelContext

    init(llmService: any LLMService, providerType: LLMProviderType, modelContext: ModelContext) {
        self.llmService = llmService
        self.providerUsed = providerType
        self.modelContext = modelContext
    }

    func generateInsight(
        from snapshot: HealthSnapshot,
        userAge: Int,
        biologicalSex: String
    ) async {
        isGenerating = true
        error = nil
        currentInsight = nil

        do {
            // Actor hop: call the actor-isolated service, await the result
            let insight = try await llmService.generateInsight(
                from: snapshot,
                userAge: userAge,
                biologicalSex: biologicalSex
            )
            currentInsight = insight
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }

    func saveCurrentInsight(weekStartDate: Date = Date()) {
        guard let insight = currentInsight, !isSaved else { return }
        let record = InsightRecord(
            id: UUID(),
            createdAt: Date(),
            summary: insight.summary,
            trend: insight.overallTrend.rawValue,
            recommendations: insight.recommendations,
            providerUsed: providerUsed.rawValue,
            weekStartDate: weekStartDate
        )
        modelContext.insert(record)
        try? modelContext.save()
        isSaved = true
    }
}
