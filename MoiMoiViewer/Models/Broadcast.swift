import Foundation
import SwiftData

@Model
final class Broadcast {
    var id: String
    var date: Date
    var title: String
    var performerNames: [String]
    var songTitles: [String]
    var resultNote: String
    var isSpecialEpisode: Bool
    var sourceURLString: String
    var isFavorite: Bool
    var updatedAt: Date

    init(
        id: String,
        date: Date,
        title: String = "",
        performerNames: [String] = [],
        songTitles: [String] = [],
        resultNote: String = "",
        isSpecialEpisode: Bool = false,
        sourceURLString: String,
        isFavorite: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.performerNames = performerNames
        self.songTitles = songTitles
        self.resultNote = resultNote
        self.isSpecialEpisode = isSpecialEpisode
        self.sourceURLString = sourceURLString
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }
}

extension Broadcast {
    static func predicate(text: String, performerName: String?, start: Date?, end: Date?) -> Predicate<Broadcast> {
        #Predicate<Broadcast> { broadcast in
            (text.isEmpty
                || broadcast.title.localizedStandardContains(text)
                || broadcast.resultNote.localizedStandardContains(text))
                && (performerName == nil || broadcast.performerNames.contains(performerName!))
                && (start == nil || broadcast.date >= start!)
                && (end == nil || broadcast.date < end!)
        }
    }
}
