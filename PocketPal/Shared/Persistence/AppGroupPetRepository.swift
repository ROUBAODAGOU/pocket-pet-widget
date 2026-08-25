import Foundation

private final class FileCoordinationResultBox<Value>: @unchecked Sendable {
    var result: Result<Value, Error>?
}

final class AppGroupPetRepository: PetRepository, @unchecked Sendable {
    static let primaryFileName = "game-state.json"
    static let backupFileName = "game-state.backup.json"

    private struct SchemaHeader: Decodable {
        var schemaVersion: Int
    }

    private let directoryURL: URL
    private let lock = NSLock()

    init(location: SharedContainerLocation) throws {
        directoryURL = try SharedContainerResolver.resolve(location)
    }

    func load() throws -> GameState? {
        lock.lock()
        defer { lock.unlock() }
        return try coordinateReading { directory in
            try self.loadLocked(in: directory)
        }
    }

    func save(_ state: GameState) throws {
        lock.lock()
        defer { lock.unlock() }
        try coordinateWriting { directory in
            try self.saveLocked(state, in: directory)
        }
    }

    func update(
        _ transform: @Sendable (GameState?) throws -> GameState
    ) throws -> GameState {
        lock.lock()
        defer { lock.unlock() }
        return try coordinateWriting { directory in
            let updated = try transform(try self.loadLocked(in: directory))
            try self.saveLocked(updated, in: directory)
            return updated
        }
    }

    private func primaryURL(in directory: URL) -> URL {
        directory.appendingPathComponent(Self.primaryFileName, isDirectory: false)
    }

    private func backupURL(in directory: URL) -> URL {
        directory.appendingPathComponent(Self.backupFileName, isDirectory: false)
    }

    private func loadLocked(in directory: URL) throws -> GameState? {
        let primaryURL = primaryURL(in: directory)
        let backupURL = backupURL(in: directory)
        let hasPrimary = FileManager.default.fileExists(atPath: primaryURL.path)
        let hasBackup = FileManager.default.fileExists(atPath: backupURL.path)
        guard hasPrimary || hasBackup else { return nil }

        if hasPrimary {
            do {
                return try decode(contentsOf: primaryURL)
            } catch let error as PetRepositoryError {
                if case .unsupportedSchemaVersion = error { throw error }
            } catch {
                // A malformed primary file falls through to the known-good backup.
            }
        }

        if hasBackup {
            do {
                return try decode(contentsOf: backupURL)
            } catch let error as PetRepositoryError {
                if case .unsupportedSchemaVersion = error { throw error }
            } catch {
                // Both copies are unusable; surface an error instead of resetting data.
            }
        }
        throw PetRepositoryError.unrecoverableData
    }

    private func saveLocked(_ state: GameState, in directory: URL) throws {
        do {
            try state.validate()
        } catch let error as GameStateValidationError {
            if case let .unsupportedSchemaVersion(version) = error {
                throw PetRepositoryError.unsupportedSchemaVersion(version)
            }
            throw PetRepositoryError.invalidState(String(describing: error))
        } catch {
            throw PetRepositoryError.invalidState(String(describing: error))
        }

        let encoded = try encode(state)
        let primaryURL = primaryURL(in: directory)
        let backupURL = backupURL(in: directory)
        let hasPrimary = FileManager.default.fileExists(atPath: primaryURL.path)
        let hasBackup = FileManager.default.fileExists(atPath: backupURL.path)

        if hasPrimary {
            let primaryData = try readData(from: primaryURL)
            do {
                _ = try decode(primaryData)
                try write(primaryData, to: backupURL)
            } catch let error as PetRepositoryError {
                if case .unsupportedSchemaVersion = error { throw error }
                guard hasBackup else { throw PetRepositoryError.unrecoverableData }
                _ = try decode(contentsOf: backupURL)
            } catch {
                guard hasBackup else { throw PetRepositoryError.unrecoverableData }
                _ = try decode(contentsOf: backupURL)
            }
        } else if hasBackup {
            _ = try decode(contentsOf: backupURL)
        } else {
            try write(encoded, to: backupURL)
        }

        try write(encoded, to: primaryURL)
    }

    private func coordinateReading<Value: Sendable>(
        _ operation: @escaping @Sendable (URL) throws -> Value
    ) throws -> Value {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let box = FileCoordinationResultBox<Value>()
        var coordinationError: NSError?
        coordinator.coordinate(
            readingItemAt: directoryURL,
            options: [],
            error: &coordinationError
        ) { coordinatedDirectory in
            box.result = Result {
                try operation(coordinatedDirectory)
            }
        }
        return try coordinatedResult(from: box, error: coordinationError)
    }

    private func coordinateWriting<Value: Sendable>(
        _ operation: @escaping @Sendable (URL) throws -> Value
    ) throws -> Value {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let box = FileCoordinationResultBox<Value>()
        var coordinationError: NSError?
        coordinator.coordinate(
            writingItemAt: directoryURL,
            options: [],
            error: &coordinationError
        ) { coordinatedDirectory in
            box.result = Result {
                try operation(coordinatedDirectory)
            }
        }
        return try coordinatedResult(from: box, error: coordinationError)
    }

    private func coordinatedResult<Value>(
        from box: FileCoordinationResultBox<Value>,
        error: NSError?
    ) throws -> Value {
        if let error {
            throw PetRepositoryError.ioFailure(error.localizedDescription)
        }
        guard let result = box.result else {
            throw PetRepositoryError.ioFailure("File coordination did not run")
        }
        return try result.get()
    }

    private func encode(_ state: GameState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do {
            return try encoder.encode(state)
        } catch {
            throw PetRepositoryError.invalidState(error.localizedDescription)
        }
    }

    private func decode(contentsOf url: URL) throws -> GameState {
        try decode(try readData(from: url))
    }

    private func decode(_ data: Data) throws -> GameState {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let header = try decoder.decode(SchemaHeader.self, from: data)
            guard header.schemaVersion == GameState.currentSchemaVersion else {
                throw PetRepositoryError.unsupportedSchemaVersion(header.schemaVersion)
            }
            let state = try decoder.decode(GameState.self, from: data)
            try state.validate()
            return state
        } catch let error as PetRepositoryError {
            throw error
        } catch let error as GameStateValidationError {
            throw PetRepositoryError.invalidState(String(describing: error))
        } catch {
            throw PetRepositoryError.unrecoverableData
        }
    }

    private func readData(from url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw PetRepositoryError.ioFailure(error.localizedDescription)
        }
    }

    private func write(_ data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PetRepositoryError.ioFailure(error.localizedDescription)
        }
    }
}
