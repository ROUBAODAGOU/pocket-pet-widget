import XCTest
@testable import PocketPal

final class AdoptPetUseCaseTests: XCTestCase {
    func testValidNameCreatesExactInitialStateAndRefreshesOnce() throws {
        let repository = InMemoryPetRepository()
        let notifier = RefreshNotifierSpy()
        let useCase = makeUseCase(repository: repository, notifier: notifier)

        let snapshot = try useCase.execute(name: "  奶糖🐱  ")
        let state = try XCTUnwrap(repository.storedState())
        let pet = try XCTUnwrap(state.pet)

        XCTAssertEqual(pet.name, "奶糖🐱")
        XCTAssertEqual(pet.mood, 80)
        XCTAssertEqual(pet.hunger, 20)
        XCTAssertEqual(pet.intimacy, 0)
        XCTAssertEqual(pet.coins, 10)
        XCTAssertEqual(state.inventory.snackCount, 5)
        XCTAssertEqual(state.inventory.ownedReusableItemIDs, ["rainbow-ball"])
        XCTAssertEqual(state.lastEvaluatedAt, TestFixtures.referenceDate)
        XCTAssertEqual(snapshot.petName, "奶糖🐱")
        XCTAssertEqual(notifier.reloadCount(), 1)
        XCTAssertEqual(repository.metrics().saveCount, 1)
    }

    func testBlankLineBreakAndOverlongNamesAreRejectedBeforeStorage() {
        let invalidNames: [(String, PetNameValidationError)] = [
            ("   \n", .empty),
            ("奶糖\n猫", .containsLineBreak),
            ("一二三四五六七八九十十一十二三", .tooLong(maximum: 12))
        ]

        for (name, expectedError) in invalidNames {
            let repository = InMemoryPetRepository()
            let notifier = RefreshNotifierSpy()
            let useCase = makeUseCase(repository: repository, notifier: notifier)

            XCTAssertThrowsError(try useCase.execute(name: name)) { error in
                XCTAssertEqual(error as? PetNameValidationError, expectedError)
            }
            XCTAssertNil(repository.storedState())
            XCTAssertEqual(repository.metrics(), .init(loadCount: 0, saveCount: 0))
            XCTAssertEqual(notifier.reloadCount(), 0)
        }
    }

    func testEmojiGraphemeCountsAsOneVisibleCharacter() throws {
        let familyEmoji = "👨‍👩‍👧‍👦"
        XCTAssertEqual(PetNameValidator.visibleCharacterCount(in: familyEmoji), 1)
        XCTAssertEqual(try PetNameValidator.validate(familyEmoji), familyEmoji)
    }

    func testInternalSpaceIsPreservedButDoesNotCountAsVisible() throws {
        XCTAssertEqual(PetNameValidator.visibleCharacterCount(in: "奶 糖"), 2)
        XCTAssertEqual(try PetNameValidator.validate("  奶 糖  "), "奶 糖")
    }

    func testStandaloneDefaultIgnorableAndCombiningMarksAreRejected() {
        let invisibleNames = ["\u{FE0F}", "\u{200D}", "\u{0301}"]

        for name in invisibleNames {
            XCTAssertEqual(PetNameValidator.visibleCharacterCount(in: name), 0)
            XCTAssertThrowsError(try PetNameValidator.validate(name)) { error in
                XCTAssertEqual(error as? PetNameValidationError, .empty)
            }
        }
    }

    func testTwelveVisibleCharactersAcceptedAndThirteenRejected() throws {
        let validRepository = InMemoryPetRepository()
        let validNotifier = RefreshNotifierSpy()
        let validUseCase = makeUseCase(
            repository: validRepository,
            notifier: validNotifier
        )
        let twelveCharacters = String(repeating: "猫", count: 12)

        _ = try validUseCase.execute(name: twelveCharacters)

        XCTAssertEqual(validRepository.storedState()?.pet?.name, twelveCharacters)
        XCTAssertEqual(validRepository.metrics().saveCount, 1)
        XCTAssertEqual(validNotifier.reloadCount(), 1)

        let invalidRepository = InMemoryPetRepository()
        let invalidNotifier = RefreshNotifierSpy()
        let invalidUseCase = makeUseCase(
            repository: invalidRepository,
            notifier: invalidNotifier
        )
        let thirteenCharacters = String(repeating: "猫", count: 13)

        XCTAssertThrowsError(try invalidUseCase.execute(name: thirteenCharacters)) { error in
            XCTAssertEqual(
                error as? PetNameValidationError,
                .tooLong(maximum: 12)
            )
        }
        XCTAssertNil(invalidRepository.storedState())
        XCTAssertEqual(invalidRepository.metrics(), .init(loadCount: 0, saveCount: 0))
        XCTAssertEqual(invalidNotifier.reloadCount(), 0)
    }

    func testExistingPetCannotBeReplaced() throws {
        let original = TestFixtures.state()
        let repository = InMemoryPetRepository(state: original)
        let notifier = RefreshNotifierSpy()
        let useCase = makeUseCase(repository: repository, notifier: notifier)

        XCTAssertThrowsError(try useCase.execute(name: "新名字")) { error in
            XCTAssertEqual(error as? PetAdoptionError, .alreadyAdopted)
        }
        XCTAssertEqual(repository.storedState(), original)
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(notifier.reloadCount(), 0)
    }

    func testSaveFailureDoesNotCommitOrRefresh() {
        let repository = InMemoryPetRepository(failureMode: .save)
        let notifier = RefreshNotifierSpy()
        let useCase = makeUseCase(repository: repository, notifier: notifier)

        XCTAssertThrowsError(try useCase.execute(name: "奶糖"))
        XCTAssertNil(repository.storedState())
        XCTAssertEqual(repository.metrics().saveCount, 0)
        XCTAssertEqual(notifier.reloadCount(), 0)
    }

    private func makeUseCase(
        repository: InMemoryPetRepository,
        notifier: RefreshNotifierSpy
    ) -> AdoptPetUseCase {
        AdoptPetUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(TestFixtures.referenceDate),
            refreshNotifier: notifier,
            engine: PetStateEngine(calendar: TestFixtures.utcCalendar)
        )
    }
}
