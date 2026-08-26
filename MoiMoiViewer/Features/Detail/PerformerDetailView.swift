import SwiftUI

struct PerformerDetailView: View {
    @Bindable var performer: Performer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(performer.name)
                    .font(.title.bold())
                Text(performer.role.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let generation = performer.generation {
                    Label("\(generation)代目", systemImage: "number")
                }

                if let tenureStart = performer.tenureStart {
                    Label(tenureLabel(start: tenureStart, end: performer.tenureEnd), systemImage: "calendar")
                }

                if !performer.biography.isEmpty {
                    Text(performer.biography)
                        .font(.body)
                }

                if let url = URL(string: performer.sourceURLString) {
                    Link("出典: moi moi で見る", destination: url)
                        .font(.footnote)
                }
            }
            .padding()
        }
        .navigationTitle(performer.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    performer.isFavorite.toggle()
                } label: {
                    Image(systemName: performer.isFavorite ? "star.fill" : "star")
                }
            }
        }
    }

    private func tenureLabel(start: Date, end: Date?) -> String {
        let startText = DateFormatter.moiMoiYearMonth.string(from: start)
        guard let end else { return "\(startText) 〜 現在" }
        return "\(startText) 〜 \(DateFormatter.moiMoiYearMonth.string(from: end))"
    }
}
