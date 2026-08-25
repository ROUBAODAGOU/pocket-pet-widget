import Foundation
import XCTest
@testable import PocketPal

final class PersistenceTests: XCTestCase {
    func testRoundTripCreatesPrimaryAndBackupCopies() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        let state = TestFixtures.state()

        try repository.save(state)

        XCTAssertEqual(try repository.load(), state)
        XCTAssertTrue(FileManager.default.fileExists(atPath: primaryURL(in: directory).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL(in: directory).path))
    }

    func testCorruptPrimaryRecoversMostRecentValidBackup() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        let firstState = TestFixtures.state(mood: 60)
        let secondState = TestFixtures.state(mood: 90)
        try repository.save(firstState)
        try repository.save(secondState)
        try Data("broken-primary".utf8).write(
            to: primaryURL(in: directory),
            options: .atomic
        )

        XCTAssertEqual(try repository.load(), firstState)
    }

    func testCorruptPrimaryAndBackupReturnsRecoverableError() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        try repository.save(TestFixtures.state())
        try Data("broken-primary".utf8).write(
            to: primaryURL(in: directory),
            options: .atomic
        )
        try Data("broken-backup".utf8).write(
            to: backupURL(in: directory),
            options: .atomic
        )

        XCTAssertThrowsError(try repository.load()) { error in
            XCTAssertEqual(error as? PetRepositoryError, .unrecoverableData)
        }
    }

    func testUnknownSchemaIsNotOverwritten() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        let futureData = Data(#"{"schemaVersion":99,"future":"data"}"#.utf8)
        try futureData.write(to: primaryURL(in: directory), options: .atomic)

        XCTAssertThrowsError(try repository.load()) { error in
            XCTAssertEqual(
                error as? PetRepositoryError,
                .unsupportedSchemaVersion(99)
            )
        }
        XCTAssertThrowsError(try repository.save(TestFixtures.state())) { error in
            XCTAssertEqual(
                error as? PetRepositoryError,
                .unsupportedSchemaVersion(99)
            )
        }
        XCTAssertEqual(try Data(contentsOf: primaryURL(in: directory)), futureData)
    }

    func testUpdateRepairsCorruptPrimaryWhenBackupIsValid() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        let original = TestFixtures.state(mood: 60)
        try repository.save(original)
        try Data("broken-primary".utf8).write(
            to: primaryURL(in: directory),
            options: .atomic
        )

        let updated = try repository.update { state in
            guard var state else { throw PetInteractionError.noPet }
            state.pet?.mood = 75
            return state
        }

        XCTAssertEqual(updated.pet?.mood, 75)
        let loaded = try XCTUnwrap(repository.load())
        XCTAssertEqual(loaded.pet?.mood, 75)
    }

    func testConcurrentRepositoryInstancesSerializeCooldownTransaction() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let firstRepository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        let secondRepository = try AppGroupPetRepository(
            location: .testingDirectory(directory)
        )
        let date = TestFixtures.referenceDate
        let engine = PetStateEngine(calendar: TestFixtures.utcCalendar)
        try firstRepository.save(TestFixtures.state(at: date, hunger: 60))

        let group = DispatchGroup()
        let queue = DispatchQueue(
            label: "PocketPal.PersistenceTests.concurrent",
            attributes: .concurrent
        )
        let firstTransformEntered = DispatchSemaphore(value: 0)
        let allowFirstTransformToFinish = DispatchSemaphore(value: 0)
        let secondTaskStarted = DispatchSemaphore(value: 0)
        let secondTransformEntered = DispatchSemaphore(value: 0)
        let outcomes = ConcurrentOutcomeCounter()

        group.enter()
        queue.async {
            defer { group.leave() }
            do {
                _ = try firstRepository.update { state in
                    firstTransformEntered.signal()
                    _ = allowFirstTransformToFinish.wait(timeout: .now() + 2)
                    guard let state else { throw PetInteractionError.noPet }
                    return try engine.perform(.feed, on: state, at: date)
                }
                outcomes.recordSuccess()
            } catch {
                outcomes.recordOtherFailure()
            }
        }

        XCTAssertEqual(firstTransformEntered.wait(timeout: .now() + 2), .success)
        group.enter()
        queue.async {
            defer { group.leave() }
            secondTaskStarted.signal()
            do {
                _ = try secondRepository.update { state in
                    secondTransformEntered.signal()
                    guard let state else { throw PetInteractionError.noPet }
                    return try engine.perform(.feed, on: state, at: date)
                }
                outcomes.recordSuccess()
            } catch let error as PetInteractionError {
                if case .blocked(.cooldown, _) = error {
                    outcomes.recordCooldownFailure()
                } else {
                    outcomes.recordOtherFailure()
                }
            } catch {
                outcomes.recordOtherFailure()
            }
        }

        XCTAssertEqual(secondTaskStarted.wait(timeout: .now() + 2), .success)
        let secondEntryBeforeRelease = secondTransformEntered.wait(timeout: .now() + 0.5)
        allowFirstTransformToFinish.signal()
        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
        XCTAssertEqual(secondEntryBeforeRelease, .timedOut)
        XCTAssertEqual(
            outcomes.counts(),
            .init(successes: 1, cooldownFailures: 1, otherFailures: 0)
        )
        let stored = try XCTUnwrap(firstRepository.load())
        XCTAssertEqual(stored.inventory.snackCount, 4)
        XCTAssertEqual(stored.history.count, 1)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PocketPalTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func primaryURL(in directory: URL) -> URL {
        directory.appendingPathComponent(
            AppGroupPetRepository.primaryFileName,
            isDirectory: false
        )
    }

    private func backupURL(in directory: URL) -> URL {
        directory.appendingPathComponent(
            AppGroupPetRepository.backupFileName,
            isDirectory: false
        )
    }
}
