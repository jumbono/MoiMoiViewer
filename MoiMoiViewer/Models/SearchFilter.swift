import Foundation

enum SearchCategory: String, CaseIterable, Identifiable {
    case performer = "出演者"
    case song = "今月の歌"
    case broadcast = "放送回"

    var id: String { rawValue }
}

struct SearchFilter: Equatable {
    var text: String = ""
    var performerName: String?
    var year: Int?
    var activeCategories: Set<SearchCategory> = Set(SearchCategory.allCases)

    var yearRange: (start: Date, end: Date)? {
        guard let year else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        guard
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
            let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            return nil
        }
        return (start, end)
    }
}
