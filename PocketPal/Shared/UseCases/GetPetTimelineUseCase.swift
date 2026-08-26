import Foundation

struct GetPetTimelineUseCase: Sendable {
    private let repository: any PetRepository
    private let dateProvider: any DateProviding
    private let engine: PetStateEngine
    private let scheduler: WidgetTimelineScheduler

    init(
        repository: any PetRepository,
        dateProvider: any DateProviding = SystemDateProvider(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
        engine = PetStateEngine(calendar: calendar)
        scheduler = WidgetTimelineScheduler(calendar: calendar)
    }

    func execute() throws -> WidgetTimelinePlan? {
        guard let state = try repository.load(), state.pet != nil else { return nil }
        let startDate = dateProvider.now()
        let dates = scheduler.dates(
            for: state,
            startingAt: startDate,
            engine: engine
        )
        let projections = dates.compactMap { date in
            engine.snapshot(from: state, at: date).map {
                WidgetTimelineProjection(date: date, snapshot: $0)
            }
        }
        guard !projections.isEmpty else { return nil }
        return WidgetTimelinePlan(projections: projections)
    }
}
