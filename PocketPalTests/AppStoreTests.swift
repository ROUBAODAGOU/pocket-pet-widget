import XCTest
@testable import PocketPal

@MainActor
final class AppStoreTests: XCTestCase {
    func testStartRoutesEmptyStateToAdoption() {
        let store = AppStore(dependencies: dependencies(load: { nil }))

        XCTAssertEqual(store.contentState, .loading)
        store.start()

        XCTAssertEqual(store.contentState, .adoption)
    }

    func testSuccessfulAdoptionShowsHomeFeedbackAndGuide() throws {
        let snapshot = try makeSnapshot()
        let store = AppStore(
            dependencies: dependencies(
                load: { nil },
                adopt: { _ in snapshot }
            )
        )
        store.start()

        store.adopt(name: "奶糖")

        XCTAssertEqual(store.contentState, .home(snapshot))
        XCTAssertEqual(store.feedbackMessage, "欢迎回家，奶糖！")
        XCTAssertTrue(store.showsWidgetGuide)
        XCTAssertNil(store.operationErrorMessage)
    }

    func testInvalidAdoptionKeepsNameScreenAndShowsSpecificError() {
        let store = AppStore(
            dependencies: dependencies(
                load: { nil },
                adopt: { _ in
                    throw PetNameValidationError.tooLong(maximum: 12)
                }
            )
        )
        store.start()

        store.adopt(name: String(repeating: "猫", count: 13))

        XCTAssertEqual(store.contentState, .adoption)
        XCTAssertEqual(store.operationErrorMessage, "名字最多只能有 12 个可见字符。")
        XCTAssertFalse(store.showsWidgetGuide)
    }

    func testFailedInteractionClearsOldSuccessFeedback() throws {
        let snapshot = try makeSnapshot()
        let store = AppStore(
            dependencies: dependencies(
                load: { nil },
                adopt: { _ in snapshot },
                interact: { _ in
                    throw PetInteractionError.blocked(.cooldown, availableAt: nil)
                }
            )
        )
        store.start()
        store.adopt(name: "奶糖")
        XCTAssertNotNil(store.feedbackMessage)

        store.perform(.pet)

        XCTAssertNil(store.feedbackMessage)
        XCTAssertEqual(store.operationErrorMessage, "正在休息，稍后再试。")
        XCTAssertEqual(store.contentState, .home(snapshot))
    }

    func testPermanentAndTransientLoadErrorsExposeCorrectRetryState() {
        let permanentStore = AppStore(
            dependencies: dependencies(load: {
                throw PetRepositoryError.unrecoverableData
            })
        )
        permanentStore.start()

        XCTAssertEqual(
            permanentStore.contentState,
            .failure(
                message: "宠物数据无法自动恢复，原文件会保留且不会被覆盖。",
                canRetry: false
            )
        )

        let transientStore = AppStore(
            dependencies: dependencies(load: {
                throw PetRepositoryError.ioFailure("temporary")
            })
        )
        transientStore.start()

        XCTAssertEqual(
            transientStore.contentState,
            .failure(message: "本地数据读写失败，请重试。", canRetry: true)
        )
    }

    func testForegroundRefreshRepeatsAndStopsWhenInactive() async throws {
        let counter = SynchronizedLoadCounter()
        let store = AppStore(
            dependencies: dependencies(load: { counter.load() }),
            foregroundRefreshInterval: .milliseconds(20)
        )
        store.start()
        store.setSceneActive(true)

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while counter.value() < 4, clock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        let activeCount = counter.value()
        XCTAssertGreaterThanOrEqual(activeCount, 4)

        store.setSceneActive(false)
        let stoppedCount = counter.value()
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(counter.value(), stoppedCount)
    }

    private func dependencies(
        load: @escaping @Sendable () throws -> WidgetSnapshot?,
        adopt: @escaping @Sendable (String) throws -> WidgetSnapshot = { _ in
            throw PetAdoptionError.missingPetAfterSave
        },
        interact: @escaping @Sendable (PetInteraction) throws -> WidgetSnapshot = { _ in
            throw PetInteractionError.noPet
        }
    ) -> AppStore.Dependencies {
        AppStore.Dependencies(
            loadSnapshot: load,
            adopt: adopt,
            interact: interact
        )
    }

    private func makeSnapshot() throws -> WidgetSnapshot {
        try XCTUnwrap(
            PetStateEngine(calendar: TestFixtures.utcCalendar).snapshot(
                from: TestFixtures.state(),
                at: TestFixtures.referenceDate
            )
        )
    }
}

private final class SynchronizedLoadCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func load() -> WidgetSnapshot? {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return nil
    }

    func value() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}
