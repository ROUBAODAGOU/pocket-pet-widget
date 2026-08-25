import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    struct Dependencies: Sendable {
        var loadSnapshot: @Sendable () throws -> WidgetSnapshot?
        var adopt: @Sendable (String) throws -> WidgetSnapshot
        var interact: @Sendable (PetInteraction) throws -> WidgetSnapshot
    }

    enum ContentState: Equatable {
        case loading
        case adoption
        case home(WidgetSnapshot)
        case failure(message: String, canRetry: Bool)
    }

    @Published private(set) var contentState: ContentState = .loading
    @Published private(set) var feedbackMessage: String?
    @Published private(set) var operationErrorMessage: String?
    @Published private(set) var isPerformingAction = false
    @Published private(set) var showsWidgetGuide = false

    private let dependencies: Dependencies?
    private let configurationErrorMessage: String?
    private let foregroundRefreshInterval: Duration
    private var hasStarted = false
    private var foregroundRefreshTask: Task<Void, Never>?

    init(
        dependencies: Dependencies,
        foregroundRefreshInterval: Duration = .seconds(30)
    ) {
        self.dependencies = dependencies
        configurationErrorMessage = nil
        self.foregroundRefreshInterval = foregroundRefreshInterval
    }

    init(configurationErrorMessage: String) {
        dependencies = nil
        self.configurationErrorMessage = configurationErrorMessage
        foregroundRefreshInterval = .seconds(30)
        contentState = .failure(message: configurationErrorMessage, canRetry: false)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        refresh()
    }

    func refresh() {
        guard let dependencies else {
            contentState = .failure(
                message: configurationErrorMessage ?? "本地数据不可用。",
                canRetry: false
            )
            return
        }
        do {
            if let snapshot = try dependencies.loadSnapshot() {
                contentState = .home(snapshot)
            } else {
                contentState = .adoption
            }
            operationErrorMessage = nil
        } catch {
            let message = userMessage(for: error)
            if case .home = contentState {
                operationErrorMessage = message
            } else {
                contentState = .failure(
                    message: message,
                    canRetry: isRetryable(error)
                )
            }
        }
    }

    func setSceneActive(_ isActive: Bool) {
        foregroundRefreshTask?.cancel()
        foregroundRefreshTask = nil
        guard isActive else { return }
        refresh()
        let refreshInterval = foregroundRefreshInterval
        foregroundRefreshTask = Task { [weak self, refreshInterval] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: refreshInterval)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                guard let self else { return }
                self.refresh()
            }
        }
    }

    func adopt(name: String) {
        guard let dependencies else {
            operationErrorMessage = configurationErrorMessage ?? "本地数据不可用。"
            return
        }
        operationErrorMessage = nil
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let snapshot = try dependencies.adopt(name)
            feedbackMessage = "欢迎回家，\(snapshot.petName)！"
            showsWidgetGuide = true
            contentState = .home(snapshot)
        } catch {
            if error as? PetAdoptionError == .alreadyAdopted {
                refresh()
            } else {
                operationErrorMessage = userMessage(for: error)
            }
        }
    }

    func perform(_ interaction: PetInteraction) {
        guard let dependencies else {
            operationErrorMessage = configurationErrorMessage ?? "本地数据不可用。"
            return
        }
        operationErrorMessage = nil
        feedbackMessage = nil
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let snapshot = try dependencies.interact(interaction)
            feedbackMessage = feedback(for: interaction)
            contentState = .home(snapshot)
        } catch {
            operationErrorMessage = userMessage(for: error)
            if case PetInteractionError.noPet = error {
                refresh()
            }
        }
    }

    func dismissWidgetGuide() {
        showsWidgetGuide = false
    }

    private func feedback(for interaction: PetInteraction) -> String {
        switch interaction {
        case .feed: "吃到饼干，肚子满足了一点。"
        case .pet: "轻轻摸了摸，它开心地眯起眼睛。"
        case .play: "和彩虹球玩了一会儿，还捡到了金币。"
        }
    }

    private func userMessage(for error: Error) -> String {
        switch error {
        case PetNameValidationError.empty:
            "请输入 1–12 个可见字符的名字。"
        case PetNameValidationError.containsLineBreak:
            "名字不能包含换行。"
        case PetNameValidationError.containsUnsupportedCharacter:
            "名字包含无法显示的控制字符。"
        case let PetNameValidationError.tooLong(maximum):
            "名字最多只能有 \(maximum) 个可见字符。"
        case PetAdoptionError.alreadyAdopted:
            "已经领养过宠物了，正在重新读取数据。"
        case PetAdoptionError.missingPetAfterSave:
            "领养状态保存异常，请重试。"
        case PetInteractionError.noPet:
            "还没有宠物，请先完成领养。"
        case let PetInteractionError.blocked(reason, availableAt):
            blockedMessage(reason: reason, availableAt: availableAt)
        case PetRepositoryError.unrecoverableData:
            "宠物数据无法自动恢复，原文件会保留且不会被覆盖。"
        case let PetRepositoryError.unsupportedSchemaVersion(version):
            "数据来自更新版本（v\(version)），请先升级 App。"
        case PetRepositoryError.containerUnavailable:
            "共享数据容器不可用，请检查 App Group 配置。"
        case PetRepositoryError.invalidState:
            "本地数据内容异常，原文件会保留且不会被覆盖。"
        case PetRepositoryError.ioFailure:
            "本地数据读写失败，请重试。"
        default:
            "操作没有完成，请重试。"
        }
    }

    private func isRetryable(_ error: Error) -> Bool {
        switch error {
        case PetRepositoryError.unrecoverableData,
             PetRepositoryError.unsupportedSchemaVersion,
             PetRepositoryError.containerUnavailable,
             PetRepositoryError.invalidState:
            false
        default:
            true
        }
    }

    private func blockedMessage(
        reason: InteractionBlockedReason,
        availableAt: Date?
    ) -> String {
        switch reason {
        case .noPet: "还没有宠物，请先完成领养。"
        case .noSnacks: "星星饼干用完了，稍后去背包补充。"
        case .notHungry: "现在还不饿，晚一点再喂吧。"
        case .cooldown:
            if let availableAt {
                return "正在休息，\(availableAt.formatted(date: .omitted, time: .shortened)) 后可再次互动。"
            }
            return "正在休息，稍后再试。"
        }
    }
}
