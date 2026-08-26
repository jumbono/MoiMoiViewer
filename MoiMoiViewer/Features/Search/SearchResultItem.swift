import Foundation

enum SearchResultItem: Identifiable, Hashable {
    case performer(Performer)
    case song(Song)
    case broadcast(Broadcast)

    var id: String {
        switch self {
        case .performer(let performer): "performer-\(performer.id)"
        case .song(let song): "song-\(song.id)"
        case .broadcast(let broadcast): "broadcast-\(broadcast.id)"
        }
    }

    var sortDate: Date {
        switch self {
        case .performer(let performer): performer.tenureStart ?? .distantPast
        case .song(let song): song.yearMonth
        case .broadcast(let broadcast): broadcast.date
        }
    }
}
