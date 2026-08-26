import SwiftUI

struct SearchResultRow: View {
    let item: SearchResultItem

    var body: some View {
        HStack(spacing: 12) {
            icon
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }

    private var icon: Image {
        switch item {
        case .performer: Image(systemName: "person.crop.circle")
        case .song: Image(systemName: "music.note")
        case .broadcast: Image(systemName: "tv")
        }
    }

    private var title: String {
        switch item {
        case .performer(let performer):
            performer.name
        case .song(let song):
            song.title
        case .broadcast(let broadcast):
            broadcast.title.isEmpty ? DateFormatter.moiMoiBroadcastDate.string(from: broadcast.date) : broadcast.title
        }
    }

    private var subtitle: String {
        switch item {
        case .performer(let performer):
            performer.role.rawValue
        case .song(let song):
            DateFormatter.moiMoiYearMonth.string(from: song.yearMonth)
        case .broadcast(let broadcast):
            DateFormatter.moiMoiBroadcastDate.string(from: broadcast.date)
        }
    }

    private var isFavorite: Bool {
        switch item {
        case .performer(let performer): performer.isFavorite
        case .song(let song): song.isFavorite
        case .broadcast(let broadcast): broadcast.isFavorite
        }
    }
}

extension DateFormatter {
    static let moiMoiYearMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let moiMoiBroadcastDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter
    }()
}
