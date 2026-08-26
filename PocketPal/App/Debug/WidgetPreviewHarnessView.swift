#if DEBUG
import SwiftUI
import WidgetKit

struct WidgetPreviewConfiguration {
    enum Family: String, CaseIterable {
        case small
        case medium
        case large

        var widgetFamily: WidgetFamily {
            switch self {
            case .small: .systemSmall
            case .medium: .systemMedium
            case .large: .systemLarge
            }
        }

        var displayName: String {
            switch self {
            case .small: "小号"
            case .medium: "中号"
            case .large: "大号"
            }
        }

        var size: CGSize {
            switch self {
            case .small: CGSize(width: 158, height: 158)
            case .medium: CGSize(width: 338, height: 158)
            case .large: CGSize(width: 338, height: 354)
            }
        }
    }

    enum Scenario: String, CaseIterable {
        case happy
        case hungry
        case sleeping
        case unadopted
        case failure
        case privacy

        var displayName: String {
            switch self {
            case .happy: "开心"
            case .hungry: "饥饿"
            case .sleeping: "睡觉"
            case .unadopted: "未领养"
            case .failure: "数据错误"
            case .privacy: "隐私保护"
            }
        }
    }

    var family: Family
    var scenario: Scenario

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("--pocketpal-widget-preview")
    }

    static var current: WidgetPreviewConfiguration {
        let arguments = ProcessInfo.processInfo.arguments
        let family = value(after: "--pocketpal-widget-family=", in: arguments)
            .flatMap { Family(rawValue: $0) } ?? .small
        let scenario = value(after: "--pocketpal-widget-state=", in: arguments)
            .flatMap { Scenario(rawValue: $0) } ?? .happy
        return WidgetPreviewConfiguration(family: family, scenario: scenario)
    }

    private static func value(after prefix: String, in arguments: [String]) -> String? {
        guard let argument = arguments.first(where: { $0.hasPrefix(prefix) }) else {
            return nil
        }
        return String(argument.dropFirst(prefix.count))
    }
}

struct WidgetPreviewHarnessView: View {
    var configuration: WidgetPreviewConfiguration

    var body: some View {
        ZStack {
            PocketPalColors.background.ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text("PocketPal · iPhone Widget")
                        .font(.title2.bold())
                        .foregroundStyle(PocketPalColors.ink)
                        .accessibilityIdentifier("widget-preview-title")
                    Text("\(configuration.family.displayName) · \(configuration.scenario.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(PocketPalColors.secondaryInk)
                        .accessibilityIdentifier("widget-preview-variant")
                }

                previewCard

                Text("Debug 预览 · 正式 App 不显示")
                    .font(.caption)
                    .foregroundStyle(PocketPalColors.secondaryInk)
            }
            .padding(20)
        }
        .accessibilityIdentifier("widget-preview-screen")
        .environment(\.accessibilityReduceMotion, true)
    }

    private var previewCard: some View {
        WidgetRootView(
            entry: entry,
            familyOverride: configuration.family.widgetFamily
        )
        .padding(16)
        .frame(
            width: configuration.family.size.width,
            height: configuration.family.size.height
        )
        .background(PocketPalColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(PocketPalColors.ink.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 16, y: 8)
        .environment(
            \.redactionReasons,
            configuration.scenario == .privacy ? .privacy : []
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("widget-preview-card")
        .accessibilityValue(
            "\(configuration.family.rawValue),\(configuration.scenario.rawValue)"
        )
    }

    private var entry: PocketPalEntry {
        let date = Date(timeIntervalSince1970: 1_725_192_000)
        switch configuration.scenario {
        case .unadopted:
            return PocketPalEntry(date: date, content: .unadopted)
        case .failure:
            return PocketPalEntry(date: date, content: .failure)
        case .happy, .privacy:
            return PocketPalEntry(
                date: date,
                content: .snapshot(snapshot(
                    date: date,
                    action: .wandering,
                    mood: 88,
                    hunger: 26,
                    intimacy: 42,
                    coins: 18
                ))
            )
        case .hungry:
            return PocketPalEntry(
                date: date,
                content: .snapshot(snapshot(
                    date: date,
                    action: .seekingFood,
                    mood: 56,
                    hunger: 82,
                    intimacy: 31,
                    coins: 12
                ))
            )
        case .sleeping:
            return PocketPalEntry(
                date: date,
                content: .snapshot(snapshot(
                    date: date,
                    action: .sleeping,
                    mood: 76,
                    hunger: 44,
                    intimacy: 37,
                    coins: 16
                ))
            )
        }
    }

    private func snapshot(
        date: Date,
        action: PetAction,
        mood: Int,
        hunger: Int,
        intimacy: Int,
        coins: Int
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: date,
            petName: "奶糖",
            action: action,
            mood: mood,
            hunger: hunger,
            intimacy: intimacy,
            coins: coins,
            snackCount: 3,
            feedAvailability: .available,
            petAvailability: .available,
            playAvailability: .available,
            latestGrowthEvent: GrowthEvent(
                occurredAt: date.addingTimeInterval(-60 * 60),
                interactionType: .pet,
                stateDelta: StateDelta(
                    mood: 10,
                    hunger: 0,
                    intimacy: 1,
                    coins: 0,
                    snackCount: 0
                ),
                messageKey: "growth.pet.success"
            )
        )
    }
}
#endif
