import Foundation
import SwiftData

@Model
final class Performer {
    var id: String
    var name: String
    var kana: String
    var roleRaw: String
    var generation: Int?
    var tenureStart: Date?
    var tenureEnd: Date?
    var biography: String
    var photoURLString: String?
    var sourceURLString: String
    var isFavorite: Bool
    var updatedAt: Date

    var role: PerformerRole {
        get { PerformerRole(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }

    var isActive: Bool { tenureEnd == nil }

    init(
        id: String,
        name: String,
        kana: String = "",
        role: PerformerRole = .other,
        generation: Int? = nil,
        tenureStart: Date? = nil,
        tenureEnd: Date? = nil,
        biography: String = "",
        photoURLString: String? = nil,
        sourceURLString: String,
        isFavorite: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kana = kana
        self.roleRaw = role.rawValue
        self.generation = generation
        self.tenureStart = tenureStart
        self.tenureEnd = tenureEnd
        self.biography = biography
        self.photoURLString = photoURLString
        self.sourceURLString = sourceURLString
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }
}

extension Performer {
    static func predicate(text: String) -> Predicate<Performer> {
        #Predicate<Performer> { performer in
            text.isEmpty
                || performer.name.localizedStandardContains(text)
                || performer.kana.localizedStandardContains(text)
        }
    }
}
