import SwiftUI
import SwiftData

@main
struct MoiMoiViewerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Performer.self, Song.self, Broadcast.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer の初期化に失敗しました: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
