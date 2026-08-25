import SwiftUI

struct InteractionButtons: View {
    var snapshot: WidgetSnapshot
    var isBusy: Bool
    var perform: (PetInteraction) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: PocketPalSpacing.small, content: buttons)
            } else {
                HStack(spacing: PocketPalSpacing.small, content: buttons)
            }
        }
    }

    @ViewBuilder
    private func buttons() -> some View {
        ForEach(PetInteraction.allCases, id: \.self) { interaction in
            let availability = snapshot.availability(for: interaction)
            Button {
                perform(interaction)
            } label: {
                VStack(spacing: PocketPalSpacing.extraSmall) {
                    Label(title(for: interaction), systemImage: icon(for: interaction))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(detail(for: interaction, availability: availability))
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(
                    foregroundColor(
                        for: interaction,
                        isAvailable: availability.isAvailable
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 58)
                .padding(.horizontal, PocketPalSpacing.small)
                .padding(.vertical, PocketPalSpacing.small)
            }
            .buttonStyle(.plain)
            .background(
                tint(for: interaction).opacity(availability.isAvailable ? 1 : 0.42),
                in: RoundedRectangle(cornerRadius: PocketPalRadius.control)
            )
            .disabled(!availability.isAvailable || isBusy)
            .accessibilityLabel(accessibilityLabel(for: interaction, availability: availability))
            .accessibilityIdentifier("interaction-\(interaction.rawValue)")
        }
    }

    private func title(for interaction: PetInteraction) -> String {
        switch interaction {
        case .feed: String(localized: "interaction.feed")
        case .pet: String(localized: "interaction.pet")
        case .play: String(localized: "interaction.play")
        }
    }

    private func icon(for interaction: PetInteraction) -> String {
        switch interaction {
        case .feed: "star.fill"
        case .pet: "hand.raised.fill"
        case .play: "circle.grid.cross.fill"
        }
    }

    private func tint(for interaction: PetInteraction) -> Color {
        switch interaction {
        case .feed: PocketPalColors.cream
        case .pet: PocketPalColors.peach
        case .play: PocketPalColors.sky
        }
    }

    private func foregroundColor(
        for interaction: PetInteraction,
        isAvailable: Bool
    ) -> Color {
        if colorScheme == .light {
            return PocketPalColors.faceInk
        }
        if interaction == .feed && isAvailable {
            return PocketPalColors.faceInk
        }
        return PocketPalColors.ink
    }

    private func detail(
        for interaction: PetInteraction,
        availability: InteractionAvailability
    ) -> String {
        if availability.isAvailable {
            return interaction == .feed ? "饼干 × \(snapshot.snackCount)" : "现在可用"
        }
        let blockedDetail: String
        switch availability.blockedReason {
        case .noSnacks: blockedDetail = "没有饼干"
        case .notHungry: blockedDetail = "现在还不饿"
        case .cooldown:
            if let availableAt = availability.availableAt {
                let seconds = max(0, availableAt.timeIntervalSince(snapshot.generatedAt))
                let minutes = max(1, Int(ceil(seconds / 60)))
                blockedDetail = "冷却 \(minutes) 分钟"
            } else {
                blockedDetail = "冷却中"
            }
        case .noPet: blockedDetail = "请先领养"
        case nil: blockedDetail = "暂不可用"
        }
        return interaction == .feed
            ? "饼干 × \(snapshot.snackCount) · \(blockedDetail)"
            : blockedDetail
    }

    private func accessibilityLabel(
        for interaction: PetInteraction,
        availability: InteractionAvailability
    ) -> String {
        "\(title(for: interaction))，\(detail(for: interaction, availability: availability))"
    }
}
