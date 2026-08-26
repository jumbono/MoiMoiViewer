import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }

            SearchView()
                .tabItem { Label("検索", systemImage: "magnifyingglass") }

            FavoritesView()
                .tabItem { Label("お気に入り", systemImage: "star") }
        }
    }
}
