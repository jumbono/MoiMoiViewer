import SwiftUI

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.footnote)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.footnote)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct ActiveFilterBar: View {
    @Binding var filter: SearchFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let performerName = filter.performerName {
                    FilterChip(title: performerName) { filter.performerName = nil }
                }
                if let year = filter.year {
                    FilterChip(title: "\(year)年") { filter.year = nil }
                }
                if filter.activeCategories.count != SearchCategory.allCases.count {
                    ForEach(Array(filter.activeCategories)) { category in
                        FilterChip(title: category.rawValue) {
                            filter.activeCategories.remove(category)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}
