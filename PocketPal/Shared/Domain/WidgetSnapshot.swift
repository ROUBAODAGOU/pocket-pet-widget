import Foundation

struct WidgetSnapshot: Equatable, Sendable {
    var generatedAt: Date
    var petName: String
    var action: PetAction
    var mood: Int
    var hunger: Int
    var intimacy: Int
    var coins: Int
    var snackCount: Int
    var feedAvailability: InteractionAvailability
    var petAvailability: InteractionAvailability
    var playAvailability: InteractionAvailability
    var latestGrowthEvent: GrowthEvent?

    func availability(for interaction: PetInteraction) -> InteractionAvailability {
        switch interaction {
        case .feed: feedAvailability
        case .pet: petAvailability
        case .play: playAvailability
        }
    }

    var contextualInteraction: PetInteraction {
        if hunger >= 70 { return .feed }
        if petAvailability.isAvailable { return .pet }
        if playAvailability.isAvailable { return .play }
        return .pet
    }
}

struct InteractionAvailability: Equatable, Sendable {
    var isAvailable: Bool
    var blockedReason: InteractionBlockedReason?
    var availableAt: Date?

    static let available = InteractionAvailability(
        isAvailable: true,
        blockedReason: nil,
        availableAt: nil
    )
}

enum InteractionBlockedReason: String, Codable, Equatable, Sendable {
    case noPet
    case noSnacks
    case notHungry
    case cooldown
}
