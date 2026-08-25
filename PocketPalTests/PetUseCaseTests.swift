import Foundation
import XCTest
@testable import PocketPal

final class PetUseCaseTests: XCTestCase {
    private let date = TestFixtures.referenceDate
    private let engine = PetStateEngine(calendar: TestFixtures.utcCalendar)

    func testQueryProjectsWithoutSavingOrRefreshing() throws {
        let start = date.addingTimeInterval(-12 * 60 * 60)
        let factState = TestFixtures.state(at: start)
        let repository = InMemoryPetRepository(state: factState)
        let useCase = GetPetSnapshotUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(date),
            engine: engine
        )

        let snapshot = try XCTUnwrap(useCase.execute())

        XCTAssertEqual(snapshot.hunger, 56)
        XCTAssertEqual(snapshot.mood, 68)
        XCTAssertEqual(repository.storedState(), factState)
        XCTAssertEqual(repository.metrics(), .init(loadCount: 1, saveCount: 0))
    }

    func testSuccessfulInteractionSavesThenRefreshesExactlyOnce() throws {
        let repository = InMemoryPetRepository(
            state: TestFixtures.state(at: date, hunger: 60)
        )
        let refreshSpy = RefreshNotifierSpy()
        let useCase = interactionUseCase(repository: repository, refreshSpy: refreshSpy)

        let snapshot = try useCase.execute(.feed)

        XCTAssertEqual(snapshot.hunger, 30)
        XCTAssertEqual(snapshot.snackCount, 4)
        XCTAssertEqual(repository.metrics().saveCount, 1)
        XCTAssertEqual(repository.storedState()?.history.count, 1)
        XCTAssertEqual(refreshSpy.reloadCount(), 1)
    }

    func testCooldownFailureDoesNotSaveRefreshOrPartiallyMutate() throws {
        let original = TestFixtures.state(
            at: date,
            cooldowns: Cooldowns(lastPettedAt: date)
        )
        let repository = InMemoryPetRepository(state: original)
        let refreshSpy = RefreshNotifierSpy()
        let useCase = interactionUseCase(repository: repository, refreshSpy: refreshSpy)

        XCTAssertThrowsError(try useCase.execute(.pet))
        XCTAssertEqual(repository.storedState(), original)
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(refreshSpy.reloadCount(), 0)
    }

    func testSaveFailureDoesNotCommitOrRefresh() throws {
        let original = TestFixtures.state(at: date, hunger: 60)
        let repository = InMemoryPetRepository(
            state: original,
            failureMode: .save
        )
        let refreshSpy = RefreshNotifierSpy()
        let useCase = interactionUseCase(repository: repository, refreshSpy: refreshSpy)

        XCTAssertThrowsError(try useCase.execute(.feed))
        XCTAssertEqual(repository.storedState(), original)
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(refreshSpy.reloadCount(), 0)
    }

    func testOnlyFirstRapidInteractionSucceeds() throws {
        let repository = InMemoryPetRepository(
            state: TestFixtures.state(at: date, hunger: 60)
        )
        let refreshSpy = RefreshNotifierSpy()
        let useCase = interactionUseCase(repository: repository, refreshSpy: refreshSpy)

        _ = try useCase.execute(.feed)
        XCTAssertThrowsError(try useCase.execute(.feed))

        XCTAssertEqual(repository.metrics().saveCount, 1)
        XCTAssertEqual(repository.storedState()?.history.count, 1)
        XCTAssertEqual(refreshSpy.reloadCount(), 1)
    }

    func testPurchaseSuccessUpdatesBothValuesAndRefreshesOnce() throws {
        let repository = InMemoryPetRepository(state: TestFixtures.state(at: date))
        let refreshSpy = RefreshNotifierSpy()
        let useCase = PurchaseSnackUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(date),
            refreshNotifier: refreshSpy,
            engine: engine
        )

        let snapshot = try useCase.execute()

        XCTAssertEqual(snapshot.coins, 7)
        XCTAssertEqual(snapshot.snackCount, 6)
        XCTAssertEqual(repository.metrics().saveCount, 1)
        XCTAssertEqual(refreshSpy.reloadCount(), 1)
    }

    func testPurchaseFailureDoesNotDeductCoinsOrRefresh() throws {
        let original = TestFixtures.state(at: date, coins: 2)
        let repository = InMemoryPetRepository(state: original)
        let refreshSpy = RefreshNotifierSpy()
        let useCase = PurchaseSnackUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(date),
            refreshNotifier: refreshSpy,
            engine: engine
        )

        XCTAssertThrowsError(try useCase.execute()) { error in
            XCTAssertEqual(error as? SnackPurchaseError, .insufficientCoins)
        }
        XCTAssertEqual(repository.storedState(), original)
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(refreshSpy.reloadCount(), 0)
    }

    func testMissingPetIsAnExplicitFailureWithoutSaveOrRefresh() throws {
        let emptyState = GameState(pet: nil, lastEvaluatedAt: date)
        let repository = InMemoryPetRepository(state: emptyState)
        let refreshSpy = RefreshNotifierSpy()
        let useCase = interactionUseCase(repository: repository, refreshSpy: refreshSpy)

        XCTAssertThrowsError(try useCase.execute(.play)) { error in
            XCTAssertEqual(error as? PetInteractionError, .noPet)
        }
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(refreshSpy.reloadCount(), 0)
    }

    private func interactionUseCase(
        repository: InMemoryPetRepository,
        refreshSpy: RefreshNotifierSpy
    ) -> PerformPetInteractionUseCase {
        PerformPetInteractionUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(date),
            refreshNotifier: refreshSpy,
            engine: engine
        )
    }
}
