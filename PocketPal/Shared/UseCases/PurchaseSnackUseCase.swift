import Foundation

struct PurchaseSnackUseCase: Sendable {
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

    func execute() throws -> WidgetSnapshot {
        let date = dateProvider.now()
        let engine = self.engine
        let updated = try repository.update { state in
            guard let state else { throw SnackPurchaseError.noPet }
            return try engine.purchaseSnack(in: state, at: date)
        }
        refreshNotifier.reloadPetWidget()
        guard let snapshot = engine.snapshot(from: updated, at: date) else {
            throw SnackPurchaseError.noPet
        }
        return snapshot
    }
}
