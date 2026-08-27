import Foundation
import SwiftData

/// `@ModelActor` はバックグラウンドの `ModelContext` を持つ actor を生成する。
/// メインスレッド（UI）をブロックせずに数千件規模のupsertを行うため、
/// あえて `@MainActor` クラスではなくこちらを使っている。
@ModelActor
actor DataSyncService {
    private let apiClient = APIClient(
        dataEndpoint: URL(
            string: "https://raw.githubusercontent.com/jumbono/MoiMoiViewer/main/data/latest.json"
        )!
    )

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
        let existing = try modelContext.fetch(FetchDescriptor<Performer>())
        let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for dto in dtos {
            if let performer = byID[dto.id] {
                performer.name = dto.name
                performer.kana = dto.kana
                performer.roleRaw = dto.role
                performer.generation = dto.generation
                performer.tenureStart = dto.tenureStart
                performer.tenureEnd = dto.tenureEnd
                performer.biography = dto.biography
                performer.photoURLString = dto.photoURLString
                performer.sourceURLString = dto.sourceURLString
                performer.updatedAt = .now
            } else {
                modelContext.insert(
                    Performer(
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
                )
            }
        }
    }

    private func upsertSongs(_ dtos: [SongDTO]) throws {
        let existing = try modelContext.fetch(FetchDescriptor<Song>())
        let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for dto in dtos {
            if let song = byID[dto.id] {
                song.title = dto.title
                song.categoryRaw = dto.category
                song.yearMonth = dto.yearMonth
                song.composer = dto.composer
                song.lyricist = dto.lyricist
                song.singerNames = dto.singerNames
                song.songDescription = dto.songDescription
                song.sourceURLString = dto.sourceURLString
                song.updatedAt = .now
            } else {
                modelContext.insert(
                    Song(
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
                )
            }
        }
    }

    private func upsertBroadcasts(_ dtos: [BroadcastDTO]) throws {
        let existing = try modelContext.fetch(FetchDescriptor<Broadcast>())
        let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for dto in dtos {
            if let broadcast = byID[dto.id] {
                broadcast.date = dto.date
                broadcast.title = dto.title
                broadcast.performerNames = dto.performerNames
                broadcast.songTitles = dto.songTitles
                broadcast.resultNote = dto.resultNote
                broadcast.isSpecialEpisode = dto.isSpecialEpisode
                broadcast.sourceURLString = dto.sourceURLString
                broadcast.rerunOfBroadcastID = dto.rerunOfBroadcastID
                broadcast.updatedAt = .now
            } else {
                modelContext.insert(
                    Broadcast(
                        id: dto.id,
                        date: dto.date,
                        title: dto.title,
                        performerNames: dto.performerNames,
                        songTitles: dto.songTitles,
                        resultNote: dto.resultNote,
                        isSpecialEpisode: dto.isSpecialEpisode,
                        sourceURLString: dto.sourceURLString,
                        rerunOfBroadcastID: dto.rerunOfBroadcastID
                    )
                )
            }
        }
    }
}
