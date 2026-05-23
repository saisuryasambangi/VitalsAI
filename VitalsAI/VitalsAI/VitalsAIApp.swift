import SwiftUI
import SwiftData

@main
struct VitalsAIApp: App {
    let modelContainer: ModelContainer = AppModelContainer.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Dashboard", systemImage: "heart.text.square") {
                    NavigationStack {
                        DashboardView()
                    }
                }
                Tab("History", systemImage: "clock.arrow.circlepath") {
                    NavigationStack {
                        HistoryView()
                    }
                }
                Tab("Settings", systemImage: "gear") {
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
