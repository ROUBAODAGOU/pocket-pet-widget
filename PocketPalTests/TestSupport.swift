import Foundation
@testable import PocketPal

enum TestFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_725_192_000)

    static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone
        }
        return calendar
    }

    static func state(
        at date: Date = referenceDate,
        mood: Int = 80,
        hunger: Int = 20,
        intimacy: Int = 0,
        coins: Int = 10,
        snacks: Int = 5,
        cooldowns: Cooldowns = .empty,
        lastInteraction: LastInteraction? = nil,
        history: [GrowthEvent] = []
    ) -> GameState {
        GameState(
            pet: Pet(
                id: UUID(),
                name: "奶糖",
                adoptedAt: date,
                mood: mood,
                hunger: hunger,
                intimacy: intimacy,
                coins: coins,
                lastInteraction: lastInteraction
            ),
            inventory: Inventory(
                snackCount: snacks,
                ownedReusableItemIDs: ["rainbow-ball"]
            ),
            cooldowns: cooldowns,
            history: history,
            lastEvaluatedAt: date
        )
    }
}

final class RefreshNotifierSpy: WidgetRefreshNotifying, @unchecked Sendable {
    private let lock = NSLock()
    private var reloads = 0

    func reloadPetWidget() {
        lock.lock()
        defer { lock.unlock() }
        reloads += 1
    }

    func reloadCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return reloads
    }
}

final class ConcurrentOutcomeCounter: @unchecked Sendable {
    struct Counts: Equatable, Sendable {
        var successes: Int
        var cooldownFailures: Int
        var otherFailures: Int
    }

    private let lock = NSLock()
    private var successes = 0
    private var cooldownFailures = 0
    private var otherFailures = 0

    func recordSuccess() {
        lock.lock()
        defer { lock.unlock() }
        successes += 1
    }

    func recordCooldownFailure() {
        lock.lock()
        defer { lock.unlock() }
        cooldownFailures += 1
    }

    func recordOtherFailure() {
        lock.lock()
        defer { lock.unlock() }
        otherFailures += 1
    }

    func counts() -> Counts {
        lock.lock()
        defer { lock.unlock() }
        return Counts(
            successes: successes,
            cooldownFailures: cooldownFailures,
            otherFailures: otherFailures
        )
    }
}
