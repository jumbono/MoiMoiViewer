import SwiftUI
import SwiftData

/// フィルタ条件に応じて3つの `@Query` を組み立て直す結果リスト。
/// `filter` が変わるたびに親から再生成される想定（SearchView 側で `.id()` 等は不要で、
/// SwiftUI が値の変化を検知して init を呼び直す）。
struct SearchResultsListView: View {
    @Query private var performers: [Performer]
    @Query private var songs: [Song]
    @Query private var broadcasts: [Broadcast]

    private let filter: SearchFilter

    init(filter: SearchFilter) {
        self.filter = filter
        let range = filter.yearRange

        _performers = Query(
            filter: Performer.predicate(text: filter.text),
            sort: [SortDescriptor(\Performer.name)]
        )
        _songs = Query(
            filter: Song.predicate(
                text: filter.text,
                singerName: filter.performerName,
                start: range?.start,
                end: range?.end
            ),
            sort: [SortDescriptor(\Song.yearMonth, order: .reverse)]
        )
        _broadcasts = Query(
            filter: Broadcast.predicate(
                text: filter.text,
                performerName: filter.performerName,
                start: range?.start,
                end: range?.end
            ),
            sort: [SortDescriptor(\Broadcast.date, order: .reverse)]
        )
    }

    private var items: [SearchResultItem] {
        var results: [SearchResultItem] = []
        if filter.activeCategories.contains(.performer) {
            results += performers.map(SearchResultItem.performer)
        }
        if filter.activeCategories.contains(.song) {
            results += songs.map(SearchResultItem.song)
        }
        if filter.activeCategories.contains(.broadcast) {
            results += broadcasts.map(SearchResultItem.broadcast)
        }
        return results.sorted { $0.sortDate > $1.sortDate }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView.search
            } else {
                List(items) { item in
                    NavigationLink(value: item) {
                        SearchResultRow(item: item)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
