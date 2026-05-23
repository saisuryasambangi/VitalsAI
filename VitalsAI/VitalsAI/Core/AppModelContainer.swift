import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([InsightRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()
}
