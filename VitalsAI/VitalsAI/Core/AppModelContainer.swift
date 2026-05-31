import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([InsightRecord.self])

        // iCloud sync via CloudKit.
        // REQUIREMENT: Enable iCloud + CloudKit in Xcode →
        //   Target → Signing & Capabilities → + iCloud → check "CloudKit"
        //   A container "iCloud.com.saisuryasambangi.VitalsAI" will be created automatically.
        // Without that capability this line falls back to local storage (no crash).
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // CloudKit not configured yet — fall back to local-only storage
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return (try? ModelContainer(for: schema, configurations: [localConfig]))
                ?? { fatalError("Could not create ModelContainer: \(error)") }()
        }
    }()
}
