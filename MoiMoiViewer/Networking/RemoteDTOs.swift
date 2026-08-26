import Foundation

/// バックエンドの収集パイプラインが moi-moi.jp のHTMLを正規化して配信する
/// JSONペイロードの形。アプリはこのJSONだけを取得し、端末上でHTMLは解析しない。
struct MoiMoiDataPayload: Codable {
    let generatedAt: Date
    let performers: [PerformerDTO]
    let songs: [SongDTO]
    let broadcasts: [BroadcastDTO]
}

struct PerformerDTO: Codable {
    let id: String
    let name: String
    let kana: String
    let role: String
    let generation: Int?
    let tenureStart: Date?
    let tenureEnd: Date?
    let biography: String
    let photoURLString: String?
    let sourceURLString: String
}

struct SongDTO: Codable {
    let id: String
    let title: String
    let category: String
    let yearMonth: Date
    let composer: String
    let lyricist: String
    let singerNames: [String]
    let songDescription: String
    let sourceURLString: String
}

struct BroadcastDTO: Codable {
    let id: String
    let date: Date
    let title: String
    let performerNames: [String]
    let songTitles: [String]
    let resultNote: String
    let isSpecialEpisode: Bool
    let sourceURLString: String
}
