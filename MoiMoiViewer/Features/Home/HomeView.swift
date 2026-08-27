import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var recentBroadcasts: [Broadcast]
    @Query(sort: \Song.yearMonth, order: .reverse) private var recentSongs: [Song]
    @Environment(\.modelContext) private var modelContext
    @State private var syncService: DataSyncService?

    init() {
        let now = Date.now
        _recentBroadcasts = Query(
            filter: #Predicate<Broadcast> { $0.date <= now },
            sort: [SortDescriptor(\Broadcast.date, order: .reverse)]
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if let currentSong = recentSongs.first {
                    Section("今月のうた") {
                        NavigationLink(value: SearchResultItem.song(currentSong)) {
                            SearchResultRow(item: .song(currentSong))
                        }
                    }
                }

                Section("最近の放送") {
                    ForEach(recentBroadcasts.prefix(20)) { broadcast in
                        NavigationLink(value: SearchResultItem.broadcast(broadcast)) {
                            SearchResultRow(item: .broadcast(broadcast))
                        }
                    }
                }
            }
            .overlay {
                if recentBroadcasts.isEmpty && recentSongs.isEmpty {
                    ContentUnavailableView(
                        "データがまだありません",
                        systemImage: "tray",
                        description: Text("下に引っ張って更新すると最新情報を取得します。")
                    )
                }
            }
            .navigationTitle("ホーム")
            .navigationDestination(for: SearchResultItem.self) { item in
                switch item {
                case .performer(let performer):
                    PerformerDetailView(performer: performer)
                case .song(let song):
                    SongDetailView(song: song)
                case .broadcast(let broadcast):
                    BroadcastDetailView(broadcast: broadcast)
                }
            }
            .refreshable {
                await syncService?.syncAll()
            }
            .task {
                if syncService == nil {
                    syncService = DataSyncService(modelContext: modelContext)
                }
                await syncService?.syncAll()
            }
        }
    }
}
