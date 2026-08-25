import Foundation

struct GrowthEvent: Codable, Equatable, Identifiable, Sendable {
    static let maximumRetainedCount = 100

    var id: UUID
    var occurredAt: Date
    var interactionType: PetInteraction
    var stateDelta: StateDelta
    var messageKey: String

    init(
        id: UUID = UUID(),
        occurredAt: Date,
        interactionType: PetInteraction,
        stateDelta: StateDelta,
        messageKey: String
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.interactionType = interactionType
        self.stateDelta = stateDelta
        self.messageKey = messageKey
    }
}

struct StateDelta: Codable, Equatable, Sendable {
    var mood: Int
    var hunger: Int
    var intimacy: Int
    var coins: Int
    var snackCount: Int
}
