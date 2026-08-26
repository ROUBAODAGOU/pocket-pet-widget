import Foundation

struct PetStateEngine: Sendable {
    private static let hour: TimeInterval = 60 * 60

    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func project(_ state: GameState, at targetDate: Date) -> GameState {
        let elapsed = targetDate.timeIntervalSince(state.lastEvaluatedAt)
        let completeHours = Int(floor(max(0, elapsed) / Self.hour))
        guard completeHours > 0 else { return state }

        var projected = state
        projected.lastEvaluatedAt = state.lastEvaluatedAt.addingTimeInterval(
            TimeInterval(completeHours) * Self.hour
        )

        guard var pet = state.pet else { return projected }
        let initialHunger = pet.hunger
        let hungerGain = completeHours >= 34 ? 100 : completeHours * 3
        pet.hunger = min(100, initialHunger + hungerGain)

        let firstHungryHour: Int
        if initialHunger >= 70 {
            firstHungryHour = 1
        } else {
            firstHungryHour = Int(ceil(Double(70 - initialHunger) / 3.0))
        }
        let hungryHours = max(0, completeHours - firstHungryHour + 1)
        let baseMoodLoss = min(pet.mood, completeHours)
        let hungryMoodLoss = hungryHours >= 50 ? 100 : hungryHours * 2
        let moodLoss = min(pet.mood, baseMoodLoss + min(pet.mood, hungryMoodLoss))
        pet.mood -= moodLoss
        projected.pet = pet
        return projected
    }

    func currentAction(in state: GameState, at date: Date) -> PetAction {
        guard let pet = state.pet else { return .wandering }
        if let lastInteraction = pet.lastInteraction,
           let action = activeInteractionAction(lastInteraction, at: date) {
            return action
        }

        let hour = calendar.component(.hour, from: date)
        if hour >= 22 || hour < 7 {
            return .sleeping
        }
        if pet.hunger >= 70 {
            return .seekingFood
        }
        if pet.mood < 40 {
            return .resting
        }
        return .wandering
    }

    func activeInteractionEndDate(in state: GameState, at date: Date) -> Date? {
        guard let interaction = state.pet?.lastInteraction else { return nil }
        let endDate = interaction.occurredAt.addingTimeInterval(
            actionDuration(for: interaction.type)
        )
        let elapsed = date.timeIntervalSince(interaction.occurredAt)
        guard elapsed >= 0, date < endDate else { return nil }
        return endDate
    }

    func availability(
        for interaction: PetInteraction,
        in state: GameState,
        at date: Date
    ) -> InteractionAvailability {
        guard let pet = state.pet else {
            return blocked(.noPet)
        }

        if interaction == .feed {
            guard state.inventory.snackCount > 0 else {
                return blocked(.noSnacks)
            }
            guard pet.hunger > 10 else {
                return blocked(.notHungry)
            }
        }

        guard let lastDate = cooldownDate(for: interaction, in: state.cooldowns) else {
            return .available
        }
        let availableAt = lastDate.addingTimeInterval(cooldownDuration(for: interaction))
        guard date < availableAt else { return .available }
        return blocked(.cooldown, availableAt: availableAt)
    }

    func perform(
        _ interaction: PetInteraction,
        on state: GameState,
        at date: Date
    ) throws -> GameState {
        var updated = project(state, at: date)
        guard updated.pet != nil else {
            throw PetInteractionError.noPet
        }
        let availability = availability(for: interaction, in: updated, at: date)
        guard availability.isAvailable else {
            throw PetInteractionError.blocked(
                availability.blockedReason ?? .cooldown,
                availableAt: availability.availableAt
            )
        }
        guard var pet = updated.pet else {
            throw PetInteractionError.noPet
        }

        let previousPet = pet
        let previousSnackCount = updated.inventory.snackCount
        switch interaction {
        case .feed:
            updated.inventory.snackCount -= 1
            pet.hunger = max(0, pet.hunger - 30)
            pet.mood = min(100, pet.mood + 5)
            pet.intimacy = min(100, pet.intimacy + 2)
            updated.cooldowns.lastFedAt = date
        case .pet:
            pet.mood = min(100, pet.mood + 10)
            pet.intimacy = min(100, pet.intimacy + 1)
            updated.cooldowns.lastPettedAt = date
        case .play:
            pet.mood = min(100, pet.mood + 15)
            pet.hunger = min(100, pet.hunger + 5)
            pet.intimacy = min(100, pet.intimacy + 3)
            let coinResult = pet.coins.addingReportingOverflow(2)
            pet.coins = coinResult.overflow ? Int.max : coinResult.partialValue
            updated.cooldowns.lastPlayedAt = date
        }

        pet.lastInteraction = LastInteraction(type: interaction, occurredAt: date)
        updated.pet = pet
        let event = GrowthEvent(
            occurredAt: date,
            interactionType: interaction,
            stateDelta: StateDelta(
                mood: pet.mood - previousPet.mood,
                hunger: pet.hunger - previousPet.hunger,
                intimacy: pet.intimacy - previousPet.intimacy,
                coins: pet.coins - previousPet.coins,
                snackCount: updated.inventory.snackCount - previousSnackCount
            ),
            messageKey: messageKey(for: interaction)
        )
        return updated.appending(event)
    }

    func purchaseSnack(in state: GameState, at date: Date) throws -> GameState {
        var updated = project(state, at: date)
        guard var pet = updated.pet else {
            throw SnackPurchaseError.noPet
        }
        guard pet.coins >= 3 else {
            throw SnackPurchaseError.insufficientCoins
        }
        guard updated.inventory.snackCount < Int.max else {
            throw SnackPurchaseError.capacityReached
        }

        pet.coins -= 3
        updated.pet = pet
        updated.inventory.snackCount += 1
        return updated
    }

    func snapshot(from state: GameState, at date: Date) -> WidgetSnapshot? {
        let projected = project(state, at: date)
        guard let pet = projected.pet else { return nil }
        return WidgetSnapshot(
            generatedAt: date,
            petName: pet.name,
            action: currentAction(in: projected, at: date),
            mood: pet.mood,
            hunger: pet.hunger,
            intimacy: pet.intimacy,
            coins: pet.coins,
            snackCount: projected.inventory.snackCount,
            feedAvailability: availability(for: .feed, in: projected, at: date),
            petAvailability: availability(for: .pet, in: projected, at: date),
            playAvailability: availability(for: .play, in: projected, at: date),
            latestGrowthEvent: projected.history.last
        )
    }

    private func activeInteractionAction(
        _ interaction: LastInteraction,
        at date: Date
    ) -> PetAction? {
        let elapsed = date.timeIntervalSince(interaction.occurredAt)
        guard elapsed >= 0, elapsed < actionDuration(for: interaction.type) else {
            return nil
        }
        switch interaction.type {
        case .feed: return .eating
        case .pet: return .enjoyingPet
        case .play: return .playing
        }
    }

    private func cooldownDate(
        for interaction: PetInteraction,
        in cooldowns: Cooldowns
    ) -> Date? {
        switch interaction {
        case .feed: cooldowns.lastFedAt
        case .pet: cooldowns.lastPettedAt
        case .play: cooldowns.lastPlayedAt
        }
    }

    private func cooldownDuration(for interaction: PetInteraction) -> TimeInterval {
        switch interaction {
        case .feed: 15 * 60
        case .pet: 10 * 60
        case .play: 30 * 60
        }
    }

    private func actionDuration(for interaction: PetInteraction) -> TimeInterval {
        switch interaction {
        case .feed: 10 * 60
        case .pet: 5 * 60
        case .play: 15 * 60
        }
    }

    private func blocked(
        _ reason: InteractionBlockedReason,
        availableAt: Date? = nil
    ) -> InteractionAvailability {
        InteractionAvailability(
            isAvailable: false,
            blockedReason: reason,
            availableAt: availableAt
        )
    }

    private func messageKey(for interaction: PetInteraction) -> String {
        switch interaction {
        case .feed: "growth.feed.success"
        case .pet: "growth.pet.success"
        case .play: "growth.play.success"
        }
    }
}

enum PetInteractionError: Error, Equatable, Sendable {
    case noPet
    case blocked(InteractionBlockedReason, availableAt: Date?)
}

enum SnackPurchaseError: Error, Equatable, Sendable {
    case noPet
    case insufficientCoins
    case capacityReached
}
