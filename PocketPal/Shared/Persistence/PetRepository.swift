import Foundation

protocol PetRepository: Sendable {
    func load() throws -> GameState?
    func save(_ state: GameState) throws
    func update(
        _ transform: @escaping @Sendable (GameState?) throws -> GameState
    ) throws -> GameState
}

enum PetRepositoryError: Error, Equatable, Sendable {
    case containerUnavailable(String)
    case unsupportedSchemaVersion(Int)
    case unrecoverableData
    case invalidState(String)
    case ioFailure(String)
}
