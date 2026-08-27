import SwiftUI

struct SmallPetWidgetView: View {
    var snapshot: WidgetSnapshot

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout(in: proxy.size)
            } else {
                standardLayout(in: proxy.size)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func standardLayout(in size: CGSize) -> some View {
        let petSize = min(size.width * 0.39, size.height * 0.42)
        return VStack(spacing: 4) {
            header

            HStack(spacing: 5) {
                PetAvatarView(action: snapshot.action, size: petSize)
                    .frame(width: size.width * 0.39)

                VStack(spacing: 2) {
                    ForEach(WidgetStatusKind.allCases) { kind in
                        WidgetCompactMetric(kind: kind, snapshot: snapshot)
                    }
                }
                .frame(width: size.width * 0.57)
            }
            .frame(maxHeight: .infinity)

            contextAction
        }
    }

    private func accessibilityLayout(in size: CGSize) -> some View {
        let petSize = min(size.width * 0.27, size.height * 0.25)
        return VStack(spacing: 3) {
            header

            HStack(spacing: 3) {
                PetAvatarView(action: snapshot.action, size: petSize)
                    .frame(width: size.width * 0.29)

                VStack(spacing: 1) {
                    ForEach(WidgetStatusKind.allCases) { kind in
                        WidgetCompactMetric(kind: kind, snapshot: snapshot)
                    }
                }
                .dynamicTypeSize(.large)
            }
            .frame(maxHeight: .infinity)

            contextAction
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(snapshot.petName)
                .font(.caption.bold())
                .foregroundStyle(PocketPalColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
            Spacer(minLength: 2)
            Text(snapshot.action.displayName)
                .font(.caption2.bold())
                .foregroundStyle(PocketPalColors.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(snapshot.petName)，正在\(snapshot.action.displayName)")
    }

    private var contextAction: some View {
        let interaction = snapshot.contextualInteraction
        let availability = snapshot.availability(for: interaction)
        return Label(interaction.widgetTitle, systemImage: interaction.widgetIcon)
            .font(.caption2.bold())
            .foregroundStyle(colorScheme == .light ? PocketPalColors.faceInk : PocketPalColors.ink)
            .frame(maxWidth: .infinity, minHeight: 22)
            .background(
                PocketPalColors.mint.opacity(availability.isAvailable ? 0.9 : 0.35),
                in: Capsule()
            )
            .accessibilityLabel(
                "建议操作，\(interaction.widgetTitle)，\(availability.isAvailable ? "现在可用" : "暂不可用")"
            )
    }
}
