import Foundation

struct AdoptPetUseCase: Sendable {
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

    func execute(name: String) throws -> WidgetSnapshot {
        let normalizedName = try PetNameValidator.validate(name)
        let date = dateProvider.now()
        let engine = self.engine
        let adoptedState = try repository.update { existingState in
            guard existingState?.pet == nil else {
                throw PetAdoptionError.alreadyAdopted
            }
            return GameState(
                pet: Pet(name: normalizedName, adoptedAt: date),
                inventory: .initial,
                lastEvaluatedAt: date
            )
        }
        guard let snapshot = engine.snapshot(from: adoptedState, at: date) else {
            throw PetAdoptionError.missingPetAfterSave
        }
        refreshNotifier.reloadPetWidget()
        return snapshot
    }
}

enum PetAdoptionError: Error, Equatable, Sendable {
    case alreadyAdopted
    case missingPetAfterSave
}
