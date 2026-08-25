import Foundation
import XCTest
@testable import PocketPal

final class StateEngineTests: XCTestCase {
    private let engine = PetStateEngine(calendar: TestFixtures.utcCalendar)

    func testProjectionAfterOneTwelveAndTwentyFourHours() throws {
        let start = TestFixtures.referenceDate
        let state = TestFixtures.state(at: start)

        let afterOneHour = engine.project(state, at: start.addingTimeInterval(60 * 60))
        XCTAssertEqual(try XCTUnwrap(afterOneHour.pet).hunger, 23)
        XCTAssertEqual(try XCTUnwrap(afterOneHour.pet).mood, 79)

        let afterTwelveHours = engine.project(state, at: start.addingTimeInterval(12 * 60 * 60))
        XCTAssertEqual(try XCTUnwrap(afterTwelveHours.pet).hunger, 56)
        XCTAssertEqual(try XCTUnwrap(afterTwelveHours.pet).mood, 68)

        let afterTwentyFourHours = engine.project(state, at: start.addingTimeInterval(24 * 60 * 60))
        XCTAssertEqual(try XCTUnwrap(afterTwentyFourHours.pet).hunger, 92)
        XCTAssertEqual(try XCTUnwrap(afterTwentyFourHours.pet).mood, 40)
    }

    func testProjectionPreservesPartialHoursAndIgnoresClockRollback() throws {
        let start = TestFixtures.referenceDate
        let state = TestFixtures.state(at: start)
        let afterNinetyMinutes = engine.project(
            state,
            at: start.addingTimeInterval(90 * 60)
        )
        XCTAssertEqual(
            afterNinetyMinutes.lastEvaluatedAt,
            start.addingTimeInterval(60 * 60)
        )
        XCTAssertEqual(try XCTUnwrap(afterNinetyMinutes.pet).hunger, 23)

        let rolledBack = engine.project(state, at: start.addingTimeInterval(-60 * 60))
        XCTAssertEqual(rolledBack, state)
    }

    func testInteractionActionOutranksSleepThenFallsBackToSleep() throws {
        let date = try XCTUnwrap(
            TestFixtures.utcCalendar.date(
                from: DateComponents(year: 2026, month: 8, day: 25, hour: 23)
            )
        )
        let state = TestFixtures.state(
            at: date,
            lastInteraction: LastInteraction(type: .play, occurredAt: date)
        )

        XCTAssertEqual(engine.currentAction(in: state, at: date), .playing)
        XCTAssertEqual(
            engine.currentAction(in: state, at: date.addingTimeInterval(15 * 60)),
            .sleeping
        )
    }

    func testNeedBasedActionPriority() {
        let date = TestFixtures.referenceDate
        XCTAssertEqual(
            engine.currentAction(in: TestFixtures.state(at: date, mood: 20, hunger: 70), at: date),
            .seekingFood
        )
        XCTAssertEqual(
            engine.currentAction(in: TestFixtures.state(at: date, mood: 39, hunger: 69), at: date),
            .resting
        )
        XCTAssertEqual(
            engine.currentAction(in: TestFixtures.state(at: date, mood: 40, hunger: 69), at: date),
            .wandering
        )
    }

    func testFeedAppliesExactDeltaAndImmediateRepeatIsBlocked() throws {
        let date = TestFixtures.referenceDate
        let state = TestFixtures.state(at: date, mood: 80, hunger: 60)
        let fed = try engine.perform(.feed, on: state, at: date)
        let pet = try XCTUnwrap(fed.pet)

        XCTAssertEqual(pet.hunger, 30)
        XCTAssertEqual(pet.mood, 85)
        XCTAssertEqual(pet.intimacy, 2)
        XCTAssertEqual(fed.inventory.snackCount, 4)
        XCTAssertEqual(fed.history.count, 1)
        XCTAssertEqual(fed.history[0].stateDelta.hunger, -30)
        XCTAssertEqual(fed.history[0].stateDelta.snackCount, -1)

        XCTAssertThrowsError(try engine.perform(.feed, on: fed, at: date)) { error in
            XCTAssertEqual(
                error as? PetInteractionError,
                .blocked(.cooldown, availableAt: date.addingTimeInterval(15 * 60))
            )
        }
    }

    func testPlayClampsAllBoundedValues() throws {
        let date = TestFixtures.referenceDate
        let state = TestFixtures.state(
            at: date,
            mood: 95,
            hunger: 98,
            intimacy: 99,
            coins: Int.max
        )
        let played = try engine.perform(.play, on: state, at: date)
        let pet = try XCTUnwrap(played.pet)

        XCTAssertEqual(pet.mood, 100)
        XCTAssertEqual(pet.hunger, 100)
        XCTAssertEqual(pet.intimacy, 100)
        XCTAssertEqual(pet.coins, Int.max)
        XCTAssertEqual(played.history[0].stateDelta.coins, 0)
    }

    func testPetAndPlayApplyExactRulesAndCooldowns() throws {
        let date = TestFixtures.referenceDate
        let original = TestFixtures.state(
            at: date,
            mood: 50,
            hunger: 40,
            intimacy: 10,
            coins: 10
        )

        let petted = try engine.perform(.pet, on: original, at: date)
        XCTAssertEqual(petted.pet?.mood, 60)
        XCTAssertEqual(petted.pet?.intimacy, 11)
        XCTAssertThrowsError(try engine.perform(.pet, on: petted, at: date))

        let played = try engine.perform(.play, on: original, at: date)
        XCTAssertEqual(played.pet?.mood, 65)
        XCTAssertEqual(played.pet?.hunger, 45)
        XCTAssertEqual(played.pet?.intimacy, 13)
        XCTAssertEqual(played.pet?.coins, 12)
        XCTAssertThrowsError(try engine.perform(.play, on: played, at: date))
    }

    func testFeedPreconditionsDoNotChangeInputState() {
        let date = TestFixtures.referenceDate
        let noSnacks = TestFixtures.state(at: date, hunger: 60, snacks: 0)
        XCTAssertThrowsError(try engine.perform(.feed, on: noSnacks, at: date)) { error in
            XCTAssertEqual(
                error as? PetInteractionError,
                .blocked(.noSnacks, availableAt: nil)
            )
        }
        XCTAssertEqual(noSnacks.inventory.snackCount, 0)

        let notHungry = TestFixtures.state(at: date, hunger: 10)
        XCTAssertThrowsError(try engine.perform(.feed, on: notHungry, at: date)) { error in
            XCTAssertEqual(
                error as? PetInteractionError,
                .blocked(.notHungry, availableAt: nil)
            )
        }
        XCTAssertEqual(notHungry.pet?.hunger, 10)
    }

    func testGrowthHistoryKeepsNewestOneHundredEvents() throws {
        let start = TestFixtures.referenceDate
        var state = TestFixtures.state(at: start, mood: 0)
        for index in 0..<101 {
            let date = start.addingTimeInterval(TimeInterval(index) * 10 * 60)
            state = try engine.perform(.pet, on: state, at: date)
        }

        XCTAssertEqual(state.history.count, 100)
        XCTAssertEqual(
            state.history.first?.occurredAt,
            start.addingTimeInterval(10 * 60)
        )
        XCTAssertEqual(
            state.history.last?.occurredAt,
            start.addingTimeInterval(100 * 10 * 60)
        )
    }
}
