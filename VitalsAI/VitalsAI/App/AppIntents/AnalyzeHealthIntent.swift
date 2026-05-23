import AppIntents
import Foundation
import SwiftData

// MARK: - Intent

struct AnalyzeHealthIntent: AppIntent {
    static let title: LocalizedStringResource = "Analyze My Health"
    static let description: IntentDescription = IntentDescription(
        "Generates an AI summary of your recent health data",
        categoryName: "Health"
    )

    static var parameterSummary: some ParameterSummary {
        Summary("Analyze my health with AI")
    }

    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let healthActor = HealthDataActor()
        try? await healthActor.requestAuthorization()

        let snapshot = try await healthActor.fetchWeeklySnapshot()

        let userAge = UserDefaults.standard.integer(forKey: "user_age")
        let userSex = UserDefaults.standard.string(forKey: "user_sex") ?? "unknown"
        let providerRaw = UserDefaults.standard.string(forKey: "preferred_provider") ?? LLMProviderType.anthropic.rawValue
        let providerType = LLMProviderType(rawValue: providerRaw) ?? .anthropic

        let service = LLMServiceFactory.make(providerType: providerType)
        let insight = try await service.generateInsight(
            from: snapshot,
            userAge: userAge > 0 ? userAge : 30,
            biologicalSex: userSex
        )

        let context = ModelContext(AppModelContainer.shared)
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: snapshot.date) ?? snapshot.date
        let record = InsightRecord(
            summary: insight.summary,
            trend: insight.overallTrend.rawValue,
            recommendations: insight.recommendations,
            providerUsed: providerType.rawValue,
            weekStartDate: weekStart
        )
        context.insert(record)
        try? context.save()

        return .result(
            value: insight.summary,
            dialog: IntentDialog(stringLiteral: insight.summary)
        )
    }
}

// MARK: - App Shortcuts Provider

struct VitalsAIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AnalyzeHealthIntent(),
            phrases: [
                "Analyze my health with \(.applicationName)",
                "Check my health in \(.applicationName)",
                "Weekly health summary in \(.applicationName)"
            ],
            shortTitle: "Analyze Health",
            systemImageName: "heart.text.square"
        )
    }
}
