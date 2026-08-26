import Foundation
import XCTest
@testable import PocketPal

final class WidgetTimelineTests: XCTestCase {
    func testTimelineReadsOnceProjectsTwelveHoursAndNeverWrites() throws {
        let calendar = TestFixtures.utcCalendar
        let start = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 25, hour: 21, minute: 30)
        ))
        let interaction = LastInteraction(type: .play, occurredAt: start)
        let state = TestFixtures.state(
            at: start,
            mood: 80,
            hunger: 68,
            cooldowns: Cooldowns(lastPlayedAt: start),
            lastInteraction: interaction
        )
        let repository = InMemoryPetRepository(state: state)
        let useCase = GetPetTimelineUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(start),
            calendar: calendar
        )

        let plan = try XCTUnwrap(useCase.execute())
        let dates = plan.projections.map(\.date)

        XCTAssertEqual(repository.metrics(), .init(loadCount: 1, saveCount: 0))
        XCTAssertEqual(repository.storedState(), state)
        XCTAssertEqual(dates.first, start)
        XCTAssertEqual(dates.last, start.addingTimeInterval(12 * 60 * 60))
        XCTAssertTrue(dates.contains(start.addingTimeInterval(15 * 60)))
        XCTAssertTrue(dates.contains(start.addingTimeInterval(30 * 60)))
        XCTAssertTrue(dates.contains(start.addingTimeInterval(60 * 60)))
        XCTAssertTrue(zip(dates, dates.dropFirst()).allSatisfy { pair in
            pair.1.timeIntervalSince(pair.0) >= WidgetTimelineScheduler.minimumEntrySpacing
        })
    }

    func testTimelineUsesSharedEngineAtActionSleepAndNeedTransitions() throws {
        let calendar = TestFixtures.utcCalendar
        let start = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 25, hour: 21, minute: 30)
        ))
        let state = TestFixtures.state(
            at: start,
            mood: 80,
            hunger: 68,
            cooldowns: Cooldowns(lastPlayedAt: start),
            lastInteraction: LastInteraction(type: .play, occurredAt: start)
        )
        let useCase = GetPetTimelineUseCase(
            repository: InMemoryPetRepository(state: state),
            dateProvider: FixedDateProvider(start),
            calendar: calendar
        )

        let projections = try XCTUnwrap(useCase.execute()).projections
        XCTAssertEqual(snapshot(at: start, in: projections)?.action, .playing)
        XCTAssertEqual(
            snapshot(at: start.addingTimeInterval(15 * 60), in: projections)?.action,
            .wandering
        )
        XCTAssertEqual(
            snapshot(at: start.addingTimeInterval(30 * 60), in: projections)?.action,
            .sleeping
        )

        let wakeDate = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 26, hour: 7)
        ))
        let wakeSnapshot = try XCTUnwrap(snapshot(at: wakeDate, in: projections))
        XCTAssertEqual(wakeSnapshot.action, .seekingFood)
        XCTAssertGreaterThanOrEqual(wakeSnapshot.hunger, 70)
    }

    func testNearTermTransitionsAreDelayedToMinimumSupportedSpacing() throws {
        let calendar = TestFixtures.utcCalendar
        let start = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 25, hour: 12)
        ))
        let state = TestFixtures.state(
            at: start,
            cooldowns: Cooldowns(lastPettedAt: start.addingTimeInterval(-9 * 60)),
            lastInteraction: LastInteraction(
                type: .pet,
                occurredAt: start.addingTimeInterval(-4 * 60)
            )
        )
        let scheduler = WidgetTimelineScheduler(calendar: calendar)

        let dates = scheduler.dates(
            for: state,
            startingAt: start,
            engine: PetStateEngine(calendar: calendar)
        )

        XCTAssertEqual(dates[1], start.addingTimeInterval(5 * 60))
        XCTAssertFalse(zip(dates, dates.dropFirst()).contains { pair in
            pair.1.timeIntervalSince(pair.0) < WidgetTimelineScheduler.minimumEntrySpacing
        })
    }

    func testUnadoptedAndFailureQueriesDoNotWrite() throws {
        let emptyRepository = InMemoryPetRepository(
            state: GameState(pet: nil, lastEvaluatedAt: TestFixtures.referenceDate)
        )
        let emptyUseCase = GetPetTimelineUseCase(
            repository: emptyRepository,
            dateProvider: FixedDateProvider(TestFixtures.referenceDate),
            calendar: TestFixtures.utcCalendar
        )
        XCTAssertNil(try emptyUseCase.execute())
        XCTAssertEqual(emptyRepository.metrics(), .init(loadCount: 1, saveCount: 0))

        let failingRepository = InMemoryPetRepository(failureMode: .load)
        let failingUseCase = GetPetTimelineUseCase(
            repository: failingRepository,
            dateProvider: FixedDateProvider(TestFixtures.referenceDate),
            calendar: TestFixtures.utcCalendar
        )
        XCTAssertThrowsError(try failingUseCase.execute())
        XCTAssertEqual(failingRepository.metrics(), .init(loadCount: 1, saveCount: 0))
    }

    func testResponseFactoryMapsNormalUnadoptedAndFailurePolicies() throws {
        let date = TestFixtures.referenceDate
        let snapshot = try XCTUnwrap(
            PetStateEngine(calendar: TestFixtures.utcCalendar).snapshot(
                from: TestFixtures.state(at: date),
                at: date
            )
        )
        let plan = WidgetTimelinePlan(
            projections: [WidgetTimelineProjection(date: date, snapshot: snapshot)]
        )

        let normal = WidgetTimelineResponseFactory.success(plan: plan, at: date)
        XCTAssertEqual(normal.reloadStrategy, .atEnd)
        XCTAssertEqual(normal.entries, [
            WidgetTimelineRenderEntry(date: date, content: .snapshot(snapshot))
        ])

        let unadopted = WidgetTimelineResponseFactory.success(plan: nil, at: date)
        XCTAssertEqual(unadopted.reloadStrategy, .never)
        XCTAssertEqual(unadopted.entries, [
            WidgetTimelineRenderEntry(date: date, content: .unadopted)
        ])

        let failure = WidgetTimelineResponseFactory.failure(at: date)
        XCTAssertEqual(
            failure.reloadStrategy,
            .after(date.addingTimeInterval(WidgetTimelineResponseFactory.failureRetryInterval))
        )
        XCTAssertEqual(failure.entries, [
            WidgetTimelineRenderEntry(date: date, content: .failure)
        ])
    }

    func testSleepTransitionsRemainOrderedAcrossDaylightSavingChanges() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        for components in [
            DateComponents(year: 2026, month: 3, day: 7, hour: 21, minute: 30),
            DateComponents(year: 2026, month: 10, day: 31, hour: 21, minute: 30)
        ] {
            let start = try XCTUnwrap(calendar.date(from: components))
            let state = TestFixtures.state(at: start, hunger: 68)
            let useCase = GetPetTimelineUseCase(
                repository: InMemoryPetRepository(state: state),
                dateProvider: FixedDateProvider(start),
                calendar: calendar
            )

            let projections = try XCTUnwrap(useCase.execute()).projections
            let dates = projections.map(\.date)
            XCTAssertEqual(dates.first, start)
            XCTAssertEqual(dates.last, start.addingTimeInterval(12 * 60 * 60))
            XCTAssertTrue(zip(dates, dates.dropFirst()).allSatisfy { pair in
                pair.1.timeIntervalSince(pair.0) >= WidgetTimelineScheduler.minimumEntrySpacing
            })

            let bedtime = try XCTUnwrap(calendar.nextDate(
                after: start,
                matching: DateComponents(hour: 22, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ))
            let wakeTime = try XCTUnwrap(calendar.nextDate(
                after: bedtime,
                matching: DateComponents(hour: 7, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ))
            XCTAssertEqual(snapshot(at: bedtime, in: projections)?.action, .sleeping)
            XCTAssertEqual(snapshot(at: wakeTime, in: projections)?.action, .seekingFood)
        }
    }

    func testTimelineStartingAtSleepBoundaryUsesBoundaryAction() throws {
        let calendar = TestFixtures.utcCalendar
        let bedtime = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 25, hour: 22)
        ))
        let wakeTime = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 26, hour: 7)
        ))

        let sleepingPlan = try XCTUnwrap(GetPetTimelineUseCase(
            repository: InMemoryPetRepository(state: TestFixtures.state(at: bedtime)),
            dateProvider: FixedDateProvider(bedtime),
            calendar: calendar
        ).execute())
        XCTAssertEqual(sleepingPlan.projections.first?.snapshot.action, .sleeping)

        let awakePlan = try XCTUnwrap(GetPetTimelineUseCase(
            repository: InMemoryPetRepository(
                state: TestFixtures.state(at: wakeTime, hunger: 70)
            ),
            dateProvider: FixedDateProvider(wakeTime),
            calendar: calendar
        ).execute())
        XCTAssertEqual(awakePlan.projections.first?.snapshot.action, .seekingFood)
    }

    private func snapshot(
        at date: Date,
        in projections: [WidgetTimelineProjection]
    ) -> WidgetSnapshot? {
        projections.first(where: { $0.date == date })?.snapshot
    }
}
