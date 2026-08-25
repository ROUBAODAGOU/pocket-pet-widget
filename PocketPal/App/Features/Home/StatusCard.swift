import SwiftUI

struct StatusCard: View {
    enum Kind: String {
        case mood
        case hunger
        case intimacy
        case coins

        var title: String {
            switch self {
            case .mood: String(localized: "status.mood")
            case .hunger: String(localized: "status.hunger")
            case .intimacy: String(localized: "status.intimacy")
            case .coins: String(localized: "status.coins")
            }
        }

        var icon: String {
            switch self {
            case .mood: "face.smiling.fill"
            case .hunger: "fork.knife"
            case .intimacy: "heart.fill"
            case .coins: "sparkles"
            }
        }

        var tint: Color {
            switch self {
            case .mood: PocketPalColors.peach
            case .hunger: PocketPalColors.cream
            case .intimacy: PocketPalColors.lavender
            case .coins: PocketPalColors.sky
            }
        }
    }

    var kind: Kind
    var value: Int

    var body: some View {
        HStack(spacing: PocketPalSpacing.medium) {
            Image(systemName: kind.icon)
                .font(.title2)
                .foregroundStyle(PocketPalColors.faceInk)
                .frame(width: 42, height: 42)
                .background(kind.tint, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PocketPalSpacing.extraSmall) {
                Text(kind.title)
                    .font(.caption)
                    .foregroundStyle(PocketPalColors.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(value, format: .number)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(PocketPalColors.ink)
                    .accessibilityIdentifier("status-\(kind.rawValue)-value")
            }
            Spacer(minLength: 0)
        }
        .padding(PocketPalSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(PocketPalColors.surface, in: RoundedRectangle(cornerRadius: PocketPalRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.title)，\(value)")
        .accessibilityIdentifier("status-\(kind.rawValue)")
    }
}
