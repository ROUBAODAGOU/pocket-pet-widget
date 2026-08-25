import Foundation

final class InMemoryPetRepository: PetRepository, @unchecked Sendable {
    enum FailureMode: Equatable, Sendable {
        case none
        case load
        case save
    }

    struct Metrics: Equatable, Sendable {
        var loadCount: Int
        var saveCount: Int
    }

    private let lock = NSLock()
    private var state: GameState?
    private var failureMode: FailureMode
    private var loadCount = 0
    private var saveCount = 0

    init(state: GameState? = nil, failureMode: FailureMode = .none) {
        self.state = state
        self.failureMode = failureMode
    }

    func load() throws -> GameState? {
        lock.lock()
        defer { lock.unlock() }
        loadCount += 1
        if failureMode == .load {
            throw PetRepositoryError.ioFailure("Simulated load failure")
        }
        if let state {
            try validate(state)
        }
        return state
    }

    func save(_ state: GameState) throws {
        lock.lock()
        defer { lock.unlock() }
        try validate(state)
        if failureMode == .save {
            throw PetRepositoryError.ioFailure("Simulated save failure")
        }
        self.state = state
        saveCount += 1
    }

    func update(
        _ transform: @escaping @Sendable (GameState?) throws -> GameState
    ) throws -> GameState {
        lock.lock()
        defer { lock.unlock() }
        loadCount += 1
        if failureMode == .load {
            throw PetRepositoryError.ioFailure("Simulated load failure")
        }
        if let state {
            try validate(state)
        }

        let updated = try transform(state)
        try validate(updated)
        if failureMode == .save {
            throw PetRepositoryError.ioFailure("Simulated save failure")
        }
        state = updated
        saveCount += 1
        return updated
    }

    func setFailureMode(_ failureMode: FailureMode) {
        lock.lock()
        defer { lock.unlock() }
        self.failureMode = failureMode
    }

    func storedState() -> GameState? {
        lock.lock()
        defer { lock.unlock() }
        return state
    }

    func metrics() -> Metrics {
        lock.lock()
        defer { lock.unlock() }
        return Metrics(loadCount: loadCount, saveCount: saveCount)
    }

    private func validate(_ state: GameState) throws {
        do {
            try state.validate()
        } catch {
            throw PetRepositoryError.invalidState(String(describing: error))
        }
    }
}
