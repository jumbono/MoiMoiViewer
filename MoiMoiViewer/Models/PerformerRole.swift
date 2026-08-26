import Foundation

enum PerformerRole: String, Codable, CaseIterable, Identifiable {
    case gymnastics = "体操のお兄さん・お姉さん"
    case singing = "うたのお兄さん・お姉さん"
    case puppeteer = "人形劇・キャラクター"
    case narrator = "ナレーション"
    case other = "その他"

    var id: String { rawValue }
}
