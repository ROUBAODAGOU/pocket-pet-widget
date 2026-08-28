import SwiftUI

struct SmallPetWidgetView: View {
    var snapshot: WidgetSnapshot

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        WidgetInteractionControl(
            interaction: snapshot.contextualInteraction,
            snapshot: snapshot,
            style: .contextual
        )
    }
}
