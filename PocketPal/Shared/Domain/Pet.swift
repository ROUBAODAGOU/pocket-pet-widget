import Foundation

struct Pet: Codable, Equatable, Sendable {
    var id: UUID
    var speciesID: String
    var name: String
    var adoptedAt: Date
    var mood: Int
    var hunger: Int
    var intimacy: Int
    var coins: Int
    var lastInteraction: LastInteraction?

    init(
        id: UUID = UUID(),
        speciesID: String = PetSpeciesDefinition.creamCat.id,
        name: String,
        adoptedAt: Date,
        mood: Int = 80,
        hunger: Int = 20,
        intimacy: Int = 0,
        coins: Int = 10,
        lastInteraction: LastInteraction? = nil
    ) {
        self.id = id
        self.speciesID = speciesID
        self.name = name
        self.adoptedAt = adoptedAt
        self.mood = mood
        self.hunger = hunger
        self.intimacy = intimacy
        self.coins = coins
        self.lastInteraction = lastInteraction
    }
}

struct LastInteraction: Codable, Equatable, Sendable {
    var type: PetInteraction
    var occurredAt: Date
}

enum PetInteraction: String, Codable, CaseIterable, Hashable, Sendable {
    case feed
    case pet
    case play
}

enum PetAction: String, Codable, Equatable, Sendable {
    case eating
    case enjoyingPet
    case playing
    case sleeping
    case seekingFood
    case resting
    case wandering

    var displayName: String {
        switch self {
        case .eating: "吃饭"
        case .enjoyingPet: "享受抚摸"
        case .playing: "玩耍"
        case .sleeping: "睡觉"
        case .seekingFood: "找吃的"
        case .resting: "发呆"
        case .wandering: "闲逛"
        }
    }
}

struct Cooldowns: Codable, Equatable, Sendable {
    var lastFedAt: Date?
    var lastPettedAt: Date?
    var lastPlayedAt: Date?

    static let empty = Cooldowns()
}
