import SwiftUI

struct BroadcastDetailView: View {
    @Bindable var broadcast: Broadcast

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(DateFormatter.moiMoiBroadcastDate.string(from: broadcast.date))
                    .font(.title2.bold())

                if !broadcast.title.isEmpty {
                    Text(broadcast.title)
                        .font(.headline)
                }

                if broadcast.isSpecialEpisode {
                    Label("スペシャル回", systemImage: "sparkles")
                        .foregroundStyle(.orange)
                }

                if !broadcast.performerNames.isEmpty {
                    Label(broadcast.performerNames.joined(separator: "、"), systemImage: "person.2")
                }

                if !broadcast.songTitles.isEmpty {
                    Label(broadcast.songTitles.joined(separator: "、"), systemImage: "music.note.list")
                }

                if !broadcast.resultNote.isEmpty {
                    Text(broadcast.resultNote)
                        .font(.body)
                }

                if let url = URL(string: broadcast.sourceURLString) {
                    Link("出典: moi moi で見る", destination: url)
                        .font(.footnote)
                }
            }
            .padding()
        }
        .navigationTitle("放送回")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    broadcast.isFavorite.toggle()
                } label: {
                    Image(systemName: broadcast.isFavorite ? "star.fill" : "star")
                }
            }
        }
    }
}
