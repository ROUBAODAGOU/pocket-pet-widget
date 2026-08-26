import Foundation
import WidgetKit

struct PocketPalTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PocketPalEntry {
        PocketPalEntry(date: .now, content: .placeholder)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (PocketPalEntry) -> Void
    ) {
        if context.isPreview {
            completion(PocketPalEntry(date: .now, content: .snapshot(.preview)))
            return
        }

        completion(loadCurrentEntry(at: .now))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<PocketPalEntry>) -> Void
    ) {
        let now = Date()
        let response: WidgetTimelineResponse
        do {
            response = WidgetTimelineResponseFactory.success(
                plan: try makeUseCase().execute(),
                at: now
            )
        } catch {
            response = WidgetTimelineResponseFactory.failure(at: now)
        }
        completion(makeTimeline(from: response))
    }

    private func loadCurrentEntry(at date: Date) -> PocketPalEntry {
        do {
            guard let plan = try makeUseCase(date: date).execute(),
                  let projection = plan.projections.first else {
                return PocketPalEntry(date: date, content: .unadopted)
            }
            return PocketPalEntry(date: date, content: .snapshot(projection.snapshot))
        } catch {
            return PocketPalEntry(date: date, content: .failure)
        }
    }

    private func makeUseCase(date: Date? = nil) throws -> GetPetTimelineUseCase {
        let repository = try AppGroupPetRepository(
            location: .appGroup(identifier: ProjectConfiguration.appGroupIdentifier)
        )
        if let date {
            return GetPetTimelineUseCase(
                repository: repository,
                dateProvider: FixedDateProvider(date)
            )
        }
        return GetPetTimelineUseCase(repository: repository)
    }

    private func makeTimeline(
        from response: WidgetTimelineResponse
    ) -> Timeline<PocketPalEntry> {
        let entries = response.entries.map {
            PocketPalEntry(date: $0.date, content: $0.content)
        }
        let policy: TimelineReloadPolicy
        switch response.reloadStrategy {
        case .atEnd:
            policy = .atEnd
        case .never:
            policy = .never
        case let .after(date):
            policy = .after(date)
        }
        return Timeline(entries: entries, policy: policy)
    }
}

private extension WidgetSnapshot {
    static var preview: WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: .now,
            petName: "奶糖",
            action: .wandering,
            mood: 86,
            hunger: 28,
            intimacy: 42,
            coins: 18,
            snackCount: 4,
            feedAvailability: .available,
            petAvailability: .available,
            playAvailability: .available,
            latestGrowthEvent: nil
        )
    }
}
