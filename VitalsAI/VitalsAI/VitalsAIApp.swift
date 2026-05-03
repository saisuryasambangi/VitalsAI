import SwiftUI
import SwiftData

@main
struct VitalsAIApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([InsightRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

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
