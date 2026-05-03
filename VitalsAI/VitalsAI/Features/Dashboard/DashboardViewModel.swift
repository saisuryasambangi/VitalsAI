import SwiftUI
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    var snapshot: HealthSnapshot?
    var isLoadingHealth = false
    var healthError: String?
    var isAuthorized = false

    // @ObservationIgnored required because @AppStorage provides its own getter/setter,
    // which conflicts with @Observable's property-tracking synthesis.
    @ObservationIgnored
    @AppStorage("preferred_provider") var preferredProvider: String = LLMProviderType.anthropic.rawValue

    @ObservationIgnored
    @AppStorage("user_age") var userAge: Int = 30

    @ObservationIgnored
    @AppStorage("user_sex") var userSex: String = "unknown"

    var resolvedProvider: LLMProviderType {
        LLMProviderType(rawValue: preferredProvider) ?? .anthropic
    }

    private let healthActor: HealthDataActor

    init(healthActor: HealthDataActor = HealthDataActor()) {
        self.healthActor = healthActor
    }

    func authorizeAndFetch() async {
        isLoadingHealth = true
        healthError = nil

        do {
            try await healthActor.requestAuthorization()
            isAuthorized = true
            snapshot = try await healthActor.fetchWeeklySnapshot()
        } catch {
            healthError = error.localizedDescription
        }

        isLoadingHealth = false
    }
}
