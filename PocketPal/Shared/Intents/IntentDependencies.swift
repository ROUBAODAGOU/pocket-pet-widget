import Foundation

enum PetIntentFailure: Equatable, Sendable {
    case noPet
    case noSnacks
    case notHungry
    case cooldown
    case storage
}

enum PetIntentExecutionOutcome: Equatable, Sendable {
    case success(WidgetSnapshot)
    case failure(PetIntentFailure)
}

struct PetIntentExecutor: Sendable {
    private let useCase: PerformPetInteractionUseCase

    init(useCase: PerformPetInteractionUseCase) {
        self.useCase = useCase
    }

    func execute(_ interaction: PetInteraction) -> PetIntentExecutionOutcome {
        do {
            return .success(try useCase.execute(interaction))
        } catch PetInteractionError.noPet {
            return .failure(.noPet)
        } catch let PetInteractionError.blocked(reason, _) {
            return .failure(Self.failure(for: reason))
        } catch {
            return .failure(.storage)
        }
    }

    private static func failure(
        for reason: InteractionBlockedReason
    ) -> PetIntentFailure {
        switch reason {
        case .noPet: .noPet
        case .noSnacks: .noSnacks
        case .notHungry: .notHungry
        case .cooldown: .cooldown
        }
    }
}

enum IntentDependencies {
    static func perform(_ interaction: PetInteraction) -> PetIntentExecutionOutcome {
        do {
            return try makeExecutor(
                location: .appGroup(identifier: ProjectConfiguration.appGroupIdentifier)
            ).execute(interaction)
        } catch {
            return .failure(.storage)
        }
    }

    static func makeExecutor(
        location: SharedContainerLocation,
        dateProvider: any DateProviding = SystemDateProvider(),
        refreshNotifier: any WidgetRefreshNotifying = WidgetCenterRefreshNotifier(),
        engine: PetStateEngine = PetStateEngine()
    ) throws -> PetIntentExecutor {
        let repository = try AppGroupPetRepository(location: location)
        return makeExecutor(
            repository: repository,
            dateProvider: dateProvider,
            refreshNotifier: refreshNotifier,
            engine: engine
        )
    }

    static func makeExecutor(
        repository: any PetRepository,
        dateProvider: any DateProviding,
        refreshNotifier: any WidgetRefreshNotifying,
        engine: PetStateEngine = PetStateEngine()
    ) -> PetIntentExecutor {
        PetIntentExecutor(
            useCase: PerformPetInteractionUseCase(
                repository: repository,
                dateProvider: dateProvider,
                refreshNotifier: refreshNotifier,
                engine: engine
            )
        )
    }
}
