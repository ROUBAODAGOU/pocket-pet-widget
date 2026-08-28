import Foundation
import XCTest
@testable import PocketPal

final class AppIntentIntegrationTests: XCTestCase {
    private let date = TestFixtures.referenceDate
    private let engine = PetStateEngine(calendar: TestFixtures.utcCalendar)

    func testFeedIntentPathSavesBeforeSuccessAndReloadsExactlyOnce() throws {
        let repository = InMemoryPetRepository(
            state: TestFixtures.state(at: date, hunger: 60)
        )
        let notifier = RefreshNotifierSpy()
        let executor = makeExecutor(repository: repository, notifier: notifier)

        let outcome = executor.execute(.feed)

        guard case let .success(snapshot) = outcome else {
            return XCTFail("Expected feed success, got \(outcome)")
        }
        XCTAssertEqual(snapshot.hunger, 30)
        XCTAssertEqual(snapshot.snackCount, 4)
        XCTAssertEqual(repository.storedState()?.history.count, 1)
        XCTAssertEqual(repository.metrics().saveCount, 1)
        XCTAssertEqual(notifier.reloadCount(), 1)
    }

    func testPetAndPlayIntentPathsUseTheSameRules() throws {
        let petRepository = InMemoryPetRepository(
            state: TestFixtures.state(at: date, mood: 50, intimacy: 10)
        )
        let petNotifier = RefreshNotifierSpy()
        let petOutcome = makeExecutor(
            repository: petRepository,
            notifier: petNotifier
        ).execute(.pet)

        guard case let .success(petSnapshot) = petOutcome else {
            return XCTFail("Expected pet success, got \(petOutcome)")
        }
        XCTAssertEqual(petSnapshot.mood, 60)
        XCTAssertEqual(petSnapshot.intimacy, 11)
        XCTAssertEqual(petNotifier.reloadCount(), 1)

        let playRepository = InMemoryPetRepository(
            state: TestFixtures.state(
                at: date,
                mood: 50,
                hunger: 20,
                intimacy: 10,
                coins: 7
            )
        )
        let playNotifier = RefreshNotifierSpy()
        let playOutcome = makeExecutor(
            repository: playRepository,
            notifier: playNotifier
        ).execute(.play)

        guard case let .success(playSnapshot) = playOutcome else {
            return XCTFail("Expected play success, got \(playOutcome)")
        }
        XCTAssertEqual(playSnapshot.mood, 65)
        XCTAssertEqual(playSnapshot.hunger, 25)
        XCTAssertEqual(playSnapshot.intimacy, 13)
        XCTAssertEqual(playSnapshot.coins, 9)
        XCTAssertEqual(playNotifier.reloadCount(), 1)
    }

    func testValidationFailuresReturnRecoverableOutcomeWithoutWriteOrReload() throws {
        let noSnackState = TestFixtures.state(at: date, hunger: 60, snacks: 0)
        let noSnackRepository = InMemoryPetRepository(state: noSnackState)
        let noSnackNotifier = RefreshNotifierSpy()

        XCTAssertEqual(
            makeExecutor(
                repository: noSnackRepository,
                notifier: noSnackNotifier
            ).execute(.feed),
            .failure(.noSnacks)
        )
        XCTAssertEqual(noSnackRepository.storedState(), noSnackState)
        XCTAssertEqual(noSnackRepository.metrics().saveCount, 0)
        XCTAssertEqual(noSnackNotifier.reloadCount(), 0)

        let cooldownState = TestFixtures.state(
            at: date,
            cooldowns: Cooldowns(lastPettedAt: date)
        )
        let cooldownRepository = InMemoryPetRepository(state: cooldownState)
        let cooldownNotifier = RefreshNotifierSpy()

        XCTAssertEqual(
            makeExecutor(
                repository: cooldownRepository,
                notifier: cooldownNotifier
            ).execute(.pet),
            .failure(.cooldown)
        )
        XCTAssertEqual(cooldownRepository.storedState(), cooldownState)
        XCTAssertEqual(cooldownRepository.metrics().saveCount, 0)
        XCTAssertEqual(cooldownNotifier.reloadCount(), 0)
    }

    func testSaveFailureReturnsRecoverableOutcomeWithoutPartialCommitOrReload() throws {
        let original = TestFixtures.state(at: date, hunger: 60)
        let repository = InMemoryPetRepository(
            state: original,
            failureMode: .save
        )
        let notifier = RefreshNotifierSpy()

        let outcome = makeExecutor(
            repository: repository,
            notifier: notifier
        ).execute(.feed)

        XCTAssertEqual(outcome, .failure(.storage))
        XCTAssertEqual(repository.storedState(), original)
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(notifier.reloadCount(), 0)
    }

    func testExtensionStyleExecutionPersistsThroughSharedFileRepository() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PocketPalIntentTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let location = SharedContainerLocation.testingDirectory(directory)
        let appRepository = try AppGroupPetRepository(location: location)
        try appRepository.save(
            TestFixtures.state(
                at: date,
                mood: 50,
                hunger: 20,
                intimacy: 10,
                coins: 7
            )
        )
        let notifier = RefreshNotifierSpy()
        let extensionExecutor = try IntentDependencies.makeExecutor(
            location: location,
            dateProvider: FixedDateProvider(date),
            refreshNotifier: notifier,
            engine: engine
        )

        XCTAssertNotNil(successSnapshot(from: extensionExecutor.execute(.play)))

        let reopenedFromApp = try AppGroupPetRepository(location: location)
        let persisted = try XCTUnwrap(reopenedFromApp.load())
        XCTAssertEqual(persisted.pet?.mood, 65)
        XCTAssertEqual(persisted.pet?.hunger, 25)
        XCTAssertEqual(persisted.pet?.intimacy, 13)
        XCTAssertEqual(persisted.pet?.coins, 9)
        XCTAssertEqual(persisted.history.last?.interactionType, .play)
        XCTAssertEqual(notifier.reloadCount(), 1)
    }

    func testIntentTypesCallOnlySharedDependencyEntryPoint() throws {
        for path in [
            "PocketPal/Shared/Intents/FeedPetIntent.swift",
            "PocketPal/Shared/Intents/PetPetIntent.swift",
            "PocketPal/Shared/Intents/PlayPetIntent.swift"
        ] {
            let contents = try source(path)
            XCTAssertTrue(contents.contains(": AppIntent"), path)
            XCTAssertTrue(contents.contains("IntentDependencies.perform"), path)
            XCTAssertFalse(contents.contains("AppGroupPetRepository"), path)
            XCTAssertFalse(contents.contains("PetStateEngine"), path)
        }
    }

    private func makeExecutor(
        repository: InMemoryPetRepository,
        notifier: RefreshNotifierSpy
    ) -> PetIntentExecutor {
        IntentDependencies.makeExecutor(
            repository: repository,
            dateProvider: FixedDateProvider(date),
            refreshNotifier: notifier,
            engine: engine
        )
    }

    private func successSnapshot(
        from outcome: PetIntentExecutionOutcome
    ) -> WidgetSnapshot? {
        guard case let .success(snapshot) = outcome else { return nil }
        return snapshot
    }

    private func source(_ relativePath: String) throws -> String {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: projectRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
