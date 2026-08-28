import AppIntents
import SwiftUI

enum WidgetInteractionTarget: Equatable, Sendable {
    case intent(PetInteraction, isEnabled: Bool)
    case route(AppRoute)
}

extension WidgetSnapshot {
    func widgetInteractionTarget(
        for interaction: PetInteraction
    ) -> WidgetInteractionTarget {
        let availability = availability(for: interaction)
        if interaction == .feed, availability.blockedReason == .noSnacks {
            return .route(.backpack)
        }
        return .intent(interaction, isEnabled: availability.isAvailable)
    }
}

enum WidgetInteractionControlStyle: Sendable {
    case strip
    case contextual
}

struct WidgetInteractionControl: View {
    var interaction: PetInteraction
    var snapshot: WidgetSnapshot
    var style: WidgetInteractionControlStyle

    @Environment(\.colorScheme) private var colorScheme

    private var availability: InteractionAvailability {
        snapshot.availability(for: interaction)
    }

    var body: some View {
        Group {
            switch snapshot.widgetInteractionTarget(for: interaction) {
            case let .route(route):
                Link(destination: route.url) {
                    controlLabel
                }
            case let .intent(_, isEnabled):
                intentButton
                    .disabled(!isEnabled)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var intentButton: some View {
        switch interaction {
        case .feed:
            Button(intent: FeedPetIntent()) { controlLabel }
        case .pet:
            Button(intent: PetPetIntent()) { controlLabel }
        case .play:
            Button(intent: PlayPetIntent()) { controlLabel }
        }
    }

    @ViewBuilder
    private var controlLabel: some View {
        switch style {
        case .strip:
            HStack(spacing: 4) {
                Image(systemName: interaction.widgetIcon)
                    .accessibilityHidden(true)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .font(.caption.bold())
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                interaction.widgetTint.opacity(availability.isAvailable ? 0.88 : 0.34),
                in: RoundedRectangle(cornerRadius: 11)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
        case .contextual:
            Label(title, systemImage: interaction.widgetIcon)
                .font(.caption2.bold())
                .foregroundStyle(
                    colorScheme == .light
                        ? PocketPalColors.faceInk
                        : PocketPalColors.ink
                )
                .frame(maxWidth: .infinity, minHeight: 22)
                .background(
                    PocketPalColors.mint.opacity(availability.isAvailable ? 0.9 : 0.35),
                    in: Capsule()
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("建议操作，\(accessibilityLabel)")
        }
    }

    private var title: String {
        if interaction == .feed, availability.blockedReason == .noSnacks {
            return "补饼干"
        }
        return interaction.widgetTitle
    }

    private var foregroundColor: Color {
        if colorScheme == .light { return PocketPalColors.faceInk }
        if interaction == .feed, availability.isAvailable {
            return PocketPalColors.faceInk
        }
        return PocketPalColors.ink
    }

    private var accessibilityLabel: String {
        guard !availability.isAvailable else { return "\(title)，现在可用" }
        switch availability.blockedReason {
        case .noSnacks: return "补充饼干，当前没有饼干"
        case .notHungry: return "喂食，现在还不饿"
        case .cooldown: return "\(title)，冷却中"
        case .noPet: return "\(title)，请先领养"
        case nil: return "\(title)，暂不可用"
        }
    }
}
