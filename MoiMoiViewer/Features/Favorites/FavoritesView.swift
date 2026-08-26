import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(filter: #Predicate<Performer> { $0.isFavorite }, sort: \Performer.name)
    private var favoritePerformers: [Performer]

    @Query(filter: #Predicate<Song> { $0.isFavorite }, sort: \Song.yearMonth, order: .reverse)
    private var favoriteSongs: [Song]

    @Query(filter: #Predicate<Broadcast> { $0.isFavorite }, sort: \Broadcast.date, order: .reverse)
    private var favoriteBroadcasts: [Broadcast]

    var body: some View {
        NavigationStack {
            List {
                if !favoritePerformers.isEmpty {
                    Section("出演者") {
                        ForEach(favoritePerformers) { performer in
                            NavigationLink(value: SearchResultItem.performer(performer)) {
                                SearchResultRow(item: .performer(performer))
                            }
                        }
                    }
                }
                if !favoriteSongs.isEmpty {
                    Section("今月の歌") {
                        ForEach(favoriteSongs) { song in
                            NavigationLink(value: SearchResultItem.song(song)) {
                                SearchResultRow(item: .song(song))
                            }
                        }
                    }
                }
                if !favoriteBroadcasts.isEmpty {
                    Section("放送回") {
                        ForEach(favoriteBroadcasts) { broadcast in
                            NavigationLink(value: SearchResultItem.broadcast(broadcast)) {
                                SearchResultRow(item: .broadcast(broadcast))
                            }
                        }
                    }
                }
            }
            .overlay {
                if favoritePerformers.isEmpty && favoriteSongs.isEmpty && favoriteBroadcasts.isEmpty {
                    ContentUnavailableView(
                        "お気に入りはまだありません",
                        systemImage: "star",
                        description: Text("気になる出演者や曲、放送回をお気に入り登録すると、ここに表示されます。")
                    )
                }
            }
            .navigationTitle("お気に入り")
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
        }
    }
}
