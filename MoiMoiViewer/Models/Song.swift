import Foundation
import SwiftData

enum SongCategory: String, Codable, CaseIterable, Identifiable {
    case monthlySong = "今月のうた"
    case ending = "エンディングテーマ"
    case corner = "コーナーソング"
    case other = "その他"

    var id: String { rawValue }
}

@Model
final class Song {
    var id: String
    var title: String
    var categoryRaw: String
    /// 対象月の1日を表す Date（例: 2024年4月なら 2024-04-01）
    var yearMonth: Date
    var composer: String
    var lyricist: String
    var singerNames: [String]
    var songDescription: String
    var sourceURLString: String
    var isFavorite: Bool
    var updatedAt: Date

    var category: SongCategory {
        get { SongCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: String,
        title: String,
        category: SongCategory = .monthlySong,
        yearMonth: Date,
        composer: String = "",
        lyricist: String = "",
        singerNames: [String] = [],
        songDescription: String = "",
        sourceURLString: String,
        isFavorite: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.yearMonth = yearMonth
        self.composer = composer
        self.lyricist = lyricist
        self.singerNames = singerNames
        self.songDescription = songDescription
        self.sourceURLString = sourceURLString
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }
}

extension Song {
    static func predicate(text: String, singerName: String?, start: Date?, end: Date?) -> Predicate<Song> {
        #Predicate<Song> { song in
            (text.isEmpty || song.title.localizedStandardContains(text))
                && (singerName == nil || song.singerNames.contains(singerName!))
                && (start == nil || song.yearMonth >= start!)
                && (end == nil || song.yearMonth < end!)
        }
    }
}
