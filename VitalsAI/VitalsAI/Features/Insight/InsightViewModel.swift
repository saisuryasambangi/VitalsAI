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
    private var currentSnapshot: HealthSnapshot?

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
        currentSnapshot = snapshot
        isGenerating = true
        error = nil
        currentInsight = nil

        do {
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
        let snap = currentSnapshot
        let record = InsightRecord(
            id: UUID(),
            createdAt: Date(),
            summary: insight.summary,
            trend: insight.overallTrend.rawValue,
            recommendations: insight.recommendations,
            providerUsed: providerUsed.rawValue,
            weekStartDate: weekStartDate,
            snapshotDailySteps: snap.map { $0.steps / 7 } ?? 0,
            snapshotRestingHR: snap?.restingHeartRate ?? 0,
            snapshotHRVSDNN: snap?.hrvSDNN ?? 0,
            snapshotNightlySleep: snap.map { $0.sleepHours / 7.0 } ?? 0,
            snapshotDailyEnergy: snap.map { $0.activeEnergyKcal / 7.0 } ?? 0
        )
        modelContext.insert(record)
        try? modelContext.save()
        isSaved = true
    }
}
