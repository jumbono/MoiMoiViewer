import SwiftUI

struct SongDetailView: View {
    @Bindable var song: Song

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(song.title)
                    .font(.title.bold())
                Text(DateFormatter.moiMoiYearMonth.string(from: song.yearMonth))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !song.singerNames.isEmpty {
                    Label(song.singerNames.joined(separator: "、"), systemImage: "person.2")
                }
                if !song.composer.isEmpty {
                    Label("作曲: \(song.composer)", systemImage: "music.quarternote.3")
                }
                if !song.lyricist.isEmpty {
                    Label("作詞: \(song.lyricist)", systemImage: "pencil")
                }
                if !song.songDescription.isEmpty {
                    Text(song.songDescription)
                        .font(.body)
                }

                if let url = URL(string: song.sourceURLString) {
                    Link("出典: moi moi で見る", destination: url)
                        .font(.footnote)
                }
            }
            .padding()
        }
        .navigationTitle(song.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    song.isFavorite.toggle()
                } label: {
                    Image(systemName: song.isFavorite ? "star.fill" : "star")
                }
            }
        }
    }
}
