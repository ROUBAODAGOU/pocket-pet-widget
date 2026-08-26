import Foundation

struct WidgetTimelineProjection: Equatable, Sendable {
    var date: Date
    var snapshot: WidgetSnapshot
}

struct WidgetTimelinePlan: Equatable, Sendable {
    var projections: [WidgetTimelineProjection]
}

enum PocketPalWidgetContent: Equatable, Sendable {
    case placeholder
    case unadopted
    case snapshot(WidgetSnapshot)
    case failure
}

struct WidgetTimelineRenderEntry: Equatable, Sendable {
    var date: Date
    var content: PocketPalWidgetContent
}

enum WidgetTimelineReloadStrategy: Equatable, Sendable {
    case atEnd
    case never
    case after(Date)
}

struct WidgetTimelineResponse: Equatable, Sendable {
    var entries: [WidgetTimelineRenderEntry]
    var reloadStrategy: WidgetTimelineReloadStrategy
}

enum WidgetTimelineResponseFactory {
    static let failureRetryInterval: TimeInterval = 6 * 60 * 60

    static func success(
        plan: WidgetTimelinePlan?,
        at date: Date
    ) -> WidgetTimelineResponse {
        guard let plan else {
            return WidgetTimelineResponse(
                entries: [WidgetTimelineRenderEntry(date: date, content: .unadopted)],
                reloadStrategy: .never
            )
        }
        return WidgetTimelineResponse(
            entries: plan.projections.map {
                WidgetTimelineRenderEntry(
                    date: $0.date,
                    content: .snapshot($0.snapshot)
                )
            },
            reloadStrategy: .atEnd
        )
    }

    static func failure(at date: Date) -> WidgetTimelineResponse {
        WidgetTimelineResponse(
            entries: [WidgetTimelineRenderEntry(date: date, content: .failure)],
            reloadStrategy: .after(date.addingTimeInterval(failureRetryInterval))
        )
    }
}

struct WidgetTimelineScheduler: Sendable {
    static let horizon: TimeInterval = 12 * 60 * 60
    static let minimumEntrySpacing: TimeInterval = 5 * 60

    private static let hour: TimeInterval = 60 * 60
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func dates(
        for state: GameState,
        startingAt startDate: Date,
        engine: PetStateEngine
    ) -> [Date] {
        let endDate = startDate.addingTimeInterval(Self.horizon)
        var candidates = [startDate, endDate]

        appendHourlyProjectionDates(
            to: &candidates,
            state: state,
            startingAt: startDate,
            endingAt: endDate
        )
        appendSleepTransitionDates(
            to: &candidates,
            startingAt: startDate,
            endingAt: endDate
        )

        if let actionEndDate = engine.activeInteractionEndDate(in: state, at: startDate) {
            candidates.append(actionEndDate)
        }

        if let snapshot = engine.snapshot(from: state, at: startDate) {
            for interaction in PetInteraction.allCases {
                if let availableAt = snapshot.availability(for: interaction).availableAt {
                    candidates.append(availableAt)
                }
            }
        }

        return coalescedDates(
            candidates,
            startingAt: startDate,
            endingAt: endDate
        )
    }

    private func appendHourlyProjectionDates(
        to candidates: inout [Date],
        state: GameState,
        startingAt startDate: Date,
        endingAt endDate: Date
    ) {
        let elapsed = max(0, startDate.timeIntervalSince(state.lastEvaluatedAt))
        let nextCompleteHour = Int(floor(elapsed / Self.hour)) + 1
        var candidate = state.lastEvaluatedAt.addingTimeInterval(
            TimeInterval(nextCompleteHour) * Self.hour
        )

        while candidate <= endDate {
            if candidate > startDate {
                candidates.append(candidate)
            }
            candidate = candidate.addingTimeInterval(Self.hour)
        }
    }

    private func appendSleepTransitionDates(
        to candidates: inout [Date],
        startingAt startDate: Date,
        endingAt endDate: Date
    ) {
        for hour in [7, 22] {
            var cursor = startDate
            while let transition = calendar.nextDate(
                after: cursor,
                matching: DateComponents(hour: hour, minute: 0, second: 0),
                matchingPolicy: .nextTime,
                direction: .forward
            ), transition <= endDate {
                candidates.append(transition)
                cursor = transition.addingTimeInterval(1)
            }
        }
    }

    private func coalescedDates(
        _ candidates: [Date],
        startingAt startDate: Date,
        endingAt endDate: Date
    ) -> [Date] {
        let sorted = Set(candidates)
            .filter { $0 >= startDate && $0 <= endDate }
            .sorted()
        var result: [Date] = []

        for rawDate in sorted {
            let date = rawDate == startDate
                ? rawDate
                : max(rawDate, startDate.addingTimeInterval(Self.minimumEntrySpacing))
            guard date <= endDate else { continue }
            guard let lastDate = result.last else {
                result.append(date)
                continue
            }
            guard date != lastDate else { continue }

            if date.timeIntervalSince(lastDate) < Self.minimumEntrySpacing,
               result.count > 1 {
                result[result.count - 1] = date
            } else {
                result.append(date)
            }
        }

        return result
    }
}
