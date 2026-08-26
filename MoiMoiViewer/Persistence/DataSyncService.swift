import Foundation
import SwiftData

@MainActor
final class DataSyncService {
    private let modelContext: ModelContext
    private let apiClient: APIClient

    init(
        modelContext: ModelContext,
        apiClient: APIClient = APIClient(
            dataEndpoint: URL(string: "https://example.com/moimoi-data/latest.json")!
        )
    ) {
        self.modelContext = modelContext
        self.apiClient = apiClient
    }

    func syncAll() async {
        do {
            let payload = try await apiClient.fetchPayload()
            try upsertPerformers(payload.performers)
            try upsertSongs(payload.songs)
            try upsertBroadcasts(payload.broadcasts)
            try modelContext.save()
        } catch {
            print("同期に失敗しました: \(error)")
        }
    }

    private func upsertPerformers(_ dtos: [PerformerDTO]) throws {
        for dto in dtos {
            let id = dto.id
            let descriptor = FetchDescriptor<Performer>(predicate: #Predicate { $0.id == id })
            if let existing = try modelContext.fetch(descriptor).first {
                existing.name = dto.name
                existing.kana = dto.kana
                existing.roleRaw = dto.role
                existing.generation = dto.generation
                existing.tenureStart = dto.tenureStart
                existing.tenureEnd = dto.tenureEnd
                existing.biography = dto.biography
                existing.photoURLString = dto.photoURLString
                existing.sourceURLString = dto.sourceURLString
                existing.updatedAt = .now
            } else {
                let performer = Performer(
                    id: dto.id,
                    name: dto.name,
                    kana: dto.kana,
                    role: PerformerRole(rawValue: dto.role) ?? .other,
                    generation: dto.generation,
                    tenureStart: dto.tenureStart,
                    tenureEnd: dto.tenureEnd,
                    biography: dto.biography,
                    photoURLString: dto.photoURLString,
                    sourceURLString: dto.sourceURLString
                )
                modelContext.insert(performer)
            }
        }
    }

    private func upsertSongs(_ dtos: [SongDTO]) throws {
        for dto in dtos {
            let id = dto.id
            let descriptor = FetchDescriptor<Song>(predicate: #Predicate { $0.id == id })
            if let existing = try modelContext.fetch(descriptor).first {
                existing.title = dto.title
                existing.categoryRaw = dto.category
                existing.yearMonth = dto.yearMonth
                existing.composer = dto.composer
                existing.lyricist = dto.lyricist
                existing.singerNames = dto.singerNames
                existing.songDescription = dto.songDescription
                existing.sourceURLString = dto.sourceURLString
                existing.updatedAt = .now
            } else {
                let song = Song(
                    id: dto.id,
                    title: dto.title,
                    category: SongCategory(rawValue: dto.category) ?? .other,
                    yearMonth: dto.yearMonth,
                    composer: dto.composer,
                    lyricist: dto.lyricist,
                    singerNames: dto.singerNames,
                    songDescription: dto.songDescription,
                    sourceURLString: dto.sourceURLString
                )
                modelContext.insert(song)
            }
        }
    }

    private func upsertBroadcasts(_ dtos: [BroadcastDTO]) throws {
        for dto in dtos {
            let id = dto.id
            let descriptor = FetchDescriptor<Broadcast>(predicate: #Predicate { $0.id == id })
            if let existing = try modelContext.fetch(descriptor).first {
                existing.date = dto.date
                existing.title = dto.title
                existing.performerNames = dto.performerNames
                existing.songTitles = dto.songTitles
                existing.resultNote = dto.resultNote
                existing.isSpecialEpisode = dto.isSpecialEpisode
                existing.sourceURLString = dto.sourceURLString
                existing.updatedAt = .now
            } else {
                let broadcast = Broadcast(
                    id: dto.id,
                    date: dto.date,
                    title: dto.title,
                    performerNames: dto.performerNames,
                    songTitles: dto.songTitles,
                    resultNote: dto.resultNote,
                    isSpecialEpisode: dto.isSpecialEpisode,
                    sourceURLString: dto.sourceURLString
                )
                modelContext.insert(broadcast)
            }
        }
    }
}
