import SwiftUI
import SwiftData

struct SearchFilterSheet: View {
    @Binding var filter: SearchFilter
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Performer.name) private var allPerformers: [Performer]

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((1985...currentYear).reversed())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("種別") {
                    ForEach(SearchCategory.allCases) { category in
                        Toggle(
                            category.rawValue,
                            isOn: Binding(
                                get: { filter.activeCategories.contains(category) },
                                set: { isOn in
                                    if isOn {
                                        filter.activeCategories.insert(category)
                                    } else {
                                        filter.activeCategories.remove(category)
                                    }
                                }
                            )
                        )
                    }
                }

                Section("出演者") {
                    Picker("出演者で絞り込む", selection: $filter.performerName) {
                        Text("指定なし").tag(String?.none)
                        ForEach(allPerformers) { performer in
                            Text(performer.name).tag(Optional(performer.name))
                        }
                    }
                }

                Section("年") {
                    Picker("年で絞り込む", selection: $filter.year) {
                        Text("指定なし").tag(Int?.none)
                        ForEach(years, id: \.self) { year in
                            Text("\(year)年").tag(Optional(year))
                        }
                    }
                }

                Section {
                    Button("条件をリセット", role: .destructive) {
                        filter = SearchFilter(text: filter.text)
                    }
                }
            }
            .navigationTitle("絞り込み")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }
}
