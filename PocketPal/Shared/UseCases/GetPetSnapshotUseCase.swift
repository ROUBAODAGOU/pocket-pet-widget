import Foundation

struct GetPetSnapshotUseCase: Sendable {
    private let repository: any PetRepository
    private let dateProvider: any DateProviding
    private let engine: PetStateEngine

    init(
        repository: any PetRepository,
        dateProvider: any DateProviding = SystemDateProvider(),
        engine: PetStateEngine = PetStateEngine()
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
        self.engine = engine
    }

    func execute() throws -> WidgetSnapshot? {
        guard let state = try repository.load() else { return nil }
        return engine.snapshot(from: state, at: dateProvider.now())
    }
}
