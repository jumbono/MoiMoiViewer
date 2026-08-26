import SwiftUI

struct SearchView: View {
    @State private var filter = SearchFilter()
    @State private var isFilterSheetPresented = false

    var body: some View {
        NavigationStack {
            SearchResultsListView(filter: filter)
                .navigationTitle("検索")
                .searchable(text: $filter.text, prompt: "出演者・曲名・日付で検索")
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isFilterSheetPresented = true
                        } label: {
                            Label(
                                "絞り込み",
                                systemImage: activeFilterCount == 0
                                    ? "line.3.horizontal.decrease.circle"
                                    : "line.3.horizontal.decrease.circle.fill"
                            )
                        }
                    }
                }
                .safeAreaInset(edge: .top) {
                    if activeFilterCount > 0 {
                        ActiveFilterBar(filter: $filter)
                    }
                }
                .sheet(isPresented: $isFilterSheetPresented) {
                    SearchFilterSheet(filter: $filter)
                }
        }
    }

    private var activeFilterCount: Int {
        var count = 0
        if filter.performerName != nil { count += 1 }
        if filter.year != nil { count += 1 }
        if filter.activeCategories.count != SearchCategory.allCases.count { count += 1 }
        return count
    }
}
