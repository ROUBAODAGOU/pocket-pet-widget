import Foundation

struct GameState: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var pet: Pet?
    var inventory: Inventory
    var cooldowns: Cooldowns
    var history: [GrowthEvent]
    var lastEvaluatedAt: Date

    init(
        schemaVersion: Int = currentSchemaVersion,
        pet: Pet?,
        inventory: Inventory = .empty,
        cooldowns: Cooldowns = .empty,
        history: [GrowthEvent] = [],
        lastEvaluatedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.pet = pet
        self.inventory = inventory
        self.cooldowns = cooldowns
        self.history = history
        self.lastEvaluatedAt = lastEvaluatedAt
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw GameStateValidationError.unsupportedSchemaVersion(schemaVersion)
        }
        guard history.count <= GrowthEvent.maximumRetainedCount else {
            throw GameStateValidationError.tooManyGrowthEvents(history.count)
        }
        guard inventory.snackCount >= 0 else {
            throw GameStateValidationError.negativeSnackCount
        }
        guard let pet else { return }
        guard (0...100).contains(pet.mood) else {
            throw GameStateValidationError.invalidPetValue("mood")
        }
        guard (0...100).contains(pet.hunger) else {
            throw GameStateValidationError.invalidPetValue("hunger")
        }
        guard (0...100).contains(pet.intimacy) else {
            throw GameStateValidationError.invalidPetValue("intimacy")
        }
        guard pet.coins >= 0 else {
            throw GameStateValidationError.invalidPetValue("coins")
        }
    }

    func appending(_ event: GrowthEvent) -> GameState {
        var copy = self
        copy.history.append(event)
        if copy.history.count > GrowthEvent.maximumRetainedCount {
            copy.history.removeFirst(copy.history.count - GrowthEvent.maximumRetainedCount)
        }
        return copy
    }
}

enum GameStateValidationError: Error, Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
    case tooManyGrowthEvents(Int)
    case negativeSnackCount
    case invalidPetValue(String)
}
