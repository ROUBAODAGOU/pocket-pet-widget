import SwiftUI

@main
struct PocketPalApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectStatusView()
        }
    }
}

private struct ProjectStatusView: View {
    @State private var phaseTwoStatus: PhaseTwoStatus = .loading

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                Text("PocketPal")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("project-status-title")

                Text("工程骨架已连接")
                    .font(.headline)

                phaseTwoContent
            }
            .padding(24)
            .navigationTitle("项目状态")
        }
        .task {
            loadPhaseTwoSnapshot()
        }
    }

    @ViewBuilder
    private var phaseTwoContent: some View {
        switch phaseTwoStatus {
        case .loading:
            ProgressView("正在生成状态快照")
        case let .ready(snapshot):
            VStack(spacing: 12) {
                Text("Phase 2 状态引擎已连接")
                    .font(.headline)
                    .foregroundStyle(.green)

                Text("\(snapshot.petName)正在\(snapshot.action.displayName)")
                    .font(.title3.bold())
                    .accessibilityIdentifier("phase-two-snapshot")

                Grid(horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        statusLabel("心情", value: snapshot.mood)
                        statusLabel("饥饿", value: snapshot.hunger)
                    }
                    GridRow {
                        statusLabel("亲密度", value: snapshot.intimacy)
                        statusLabel("金币", value: snapshot.coins)
                    }
                }

                Text("样例快照由查询 Use Case 生成，不会写入真实宠物数据。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        case .empty:
            Text("样例状态中没有宠物")
                .foregroundStyle(.secondary)
        case .failed:
            Text("样例快照生成失败")
                .foregroundStyle(.red)
                .accessibilityIdentifier("phase-two-snapshot-error")
        }
    }

    private func statusLabel(_ title: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func loadPhaseTwoSnapshot() {
        guard case .loading = phaseTwoStatus else { return }
        do {
            if let snapshot = try PhaseTwoSampleFactory.makeSnapshot() {
                phaseTwoStatus = .ready(snapshot)
            } else {
                phaseTwoStatus = .empty
            }
        } catch {
            phaseTwoStatus = .failed
        }
    }
}

private enum PhaseTwoStatus {
    case loading
    case ready(WidgetSnapshot)
    case empty
    case failed
}

private enum PhaseTwoSampleFactory {
    static func makeSnapshot() throws -> WidgetSnapshot? {
        let snapshotDate = Date(timeIntervalSince1970: 1_725_192_000)
        let startingDate = snapshotDate.addingTimeInterval(-12 * 60 * 60)
        let pet = Pet(name: "奶糖", adoptedAt: startingDate)
        let state = GameState(
            pet: pet,
            inventory: .initial,
            lastEvaluatedAt: startingDate
        )
        let repository = InMemoryPetRepository(state: state)
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone
        }
        let useCase = GetPetSnapshotUseCase(
            repository: repository,
            dateProvider: FixedDateProvider(snapshotDate),
            engine: PetStateEngine(calendar: calendar)
        )
        return try useCase.execute()
    }
}
