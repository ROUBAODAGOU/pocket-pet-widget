import SwiftUI

struct MediumPetWidgetView: View {
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
        let petSize = min(size.width * 0.30, size.height * 0.55)
        return VStack(spacing: 7) {
            HStack(spacing: 10) {
                petHeader(size: petSize)
                    .frame(width: size.width * 0.35)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 6
                ) {
                    ForEach(WidgetStatusKind.allCases) { kind in
                        WidgetMetricCard(kind: kind, snapshot: snapshot)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            WidgetActionStrip(snapshot: snapshot)
        }
    }

    private func accessibilityLayout(in size: CGSize) -> some View {
        let petSize = min(size.width * 0.18, size.height * 0.31)
        return VStack(spacing: 4) {
            HStack(spacing: 8) {
                petHeader(size: petSize)
                    .frame(width: size.width * 0.27)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 3
                ) {
                    ForEach(WidgetStatusKind.allCases) { kind in
                        WidgetTinyMetric(kind: kind, snapshot: snapshot)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            WidgetActionStrip(snapshot: snapshot)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func petHeader(size: CGFloat) -> some View {
        VStack(spacing: 1) {
            Text(snapshot.petName)
                .font(.headline)
                .foregroundStyle(PocketPalColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(snapshot.action.displayName)
                .font(.caption.bold())
                .foregroundStyle(PocketPalColors.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            PetAvatarView(action: snapshot.action, size: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(snapshot.petName)，正在\(snapshot.action.displayName)")
    }
}
