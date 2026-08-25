import Foundation

struct PerformPetInteractionUseCase: Sendable {
    private let repository: any PetRepository
    private let dateProvider: any DateProviding
    private let refreshNotifier: any WidgetRefreshNotifying
    private let engine: PetStateEngine

    init(
        repository: any PetRepository,
        dateProvider: any DateProviding = SystemDateProvider(),
        refreshNotifier: any WidgetRefreshNotifying,
        engine: PetStateEngine = PetStateEngine()
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
        self.refreshNotifier = refreshNotifier
        self.engine = engine
    }

    func execute(_ interaction: PetInteraction) throws -> WidgetSnapshot {
        let date = dateProvider.now()
        let engine = self.engine
        let updated = try repository.update { state in
            guard let state else { throw PetInteractionError.noPet }
            return try engine.perform(interaction, on: state, at: date)
        }
        refreshNotifier.reloadPetWidget()
        guard let snapshot = engine.snapshot(from: updated, at: date) else {
            throw PetInteractionError.noPet
        }
        return snapshot
    }
}
