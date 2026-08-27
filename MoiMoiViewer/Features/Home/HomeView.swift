import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var recentBroadcasts: [Broadcast]
    @Query(sort: \Song.yearMonth, order: .reverse) private var recentSongs: [Song]
    @Environment(\.modelContext) private var modelContext
    @State private var syncService: DataSyncService?
    @State private var isSyncing = false

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
                if isSyncing && recentBroadcasts.isEmpty && recentSongs.isEmpty {
                    ProgressView("最新情報を取得中…")
                } else if recentBroadcasts.isEmpty && recentSongs.isEmpty {
                    ContentUnavailableView(
                        "データがまだありません",
                        systemImage: "tray",
                        description: Text("下に引っ張って更新すると最新情報を取得します。")
                    )
                }
            }
            .safeAreaInset(edge: .top) {
                if isSyncing && !(recentBroadcasts.isEmpty && recentSongs.isEmpty) {
                    HStack(spacing: 6) {
                        ProgressView()
                        Text("最新情報を同期中…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(.bar)
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
                await performSync()
            }
            .task {
                await performSync()
            }
        }
    }

    private func performSync() async {
        if syncService == nil {
            syncService = DataSyncService(modelContainer: modelContext.container)
        }
        isSyncing = true
        await syncService?.syncAll()
        isSyncing = false
    }
}
