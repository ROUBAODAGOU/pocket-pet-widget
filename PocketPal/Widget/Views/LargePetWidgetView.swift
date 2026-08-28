import SwiftUI

struct LargePetWidgetView: View {
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
        let petSize = min(size.width * 0.43, size.height * 0.40)
        return VStack(spacing: 10) {
            hero(size: petSize, width: size.width * 0.45)
                .frame(height: size.height * 0.40)
            progressMetrics
            WidgetActionStrip(snapshot: snapshot)
            growthSummary
        }
    }

    private func accessibilityLayout(in size: CGSize) -> some View {
        let petSize = min(size.width * 0.23, size.height * 0.23)
        return VStack(spacing: 6) {
            hero(size: petSize, width: size.width * 0.28)
                .frame(maxHeight: size.height * 0.28)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 4
            ) {
                ForEach(WidgetStatusKind.allCases) { kind in
                    WidgetMetricCard(kind: kind, snapshot: snapshot)
                }
            }

            WidgetActionStrip(snapshot: snapshot)
            growthSummary
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func hero(size: CGFloat, width: CGFloat) -> some View {
        HStack(spacing: 12) {
            PetAvatarView(action: snapshot.action, size: size)
                .frame(width: width)

            VStack(alignment: .leading, spacing: 5) {
                Text(snapshot.petName)
                    .font(.title3.bold())
                    .foregroundStyle(PocketPalColors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.58)
                Label(snapshot.action.displayName, systemImage: actionIcon)
                    .font(.caption.bold())
                    .foregroundStyle(PocketPalColors.secondaryInk)
                    .lineLimit(1)
                Text(snapshot.moodMessage)
                    .font(.subheadline)
                    .foregroundStyle(PocketPalColors.ink)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 3)
                    .minimumScaleFactor(0.62)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(snapshot.petName)，正在\(snapshot.action.displayName)，\(snapshot.moodMessage)")
    }

    private var progressMetrics: some View {
        VStack(spacing: 7) {
            ForEach(WidgetStatusKind.allCases.filter { $0 != .coins }) { kind in
                WidgetProgressMetric(kind: kind, snapshot: snapshot)
            }
            HStack {
                Label("金币", systemImage: WidgetStatusKind.coins.icon)
                    .font(.caption)
                    .foregroundStyle(PocketPalColors.secondaryInk)
                Spacer()
                Text(snapshot.coins, format: .number)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(PocketPalColors.ink)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("金币，\(snapshot.coins)")
        }
        .padding(10)
        .background(PocketPalColors.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private var growthSummary: some View {
        Link(destination: AppRoute.growth.url) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .accessibilityHidden(true)
                Text(latestGrowthText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(PocketPalColors.secondaryInk)
            .padding(.horizontal, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("打开成长页，\(latestGrowthText)")
        }
        .buttonStyle(.plain)
    }

    private var latestGrowthText: String {
        guard let event = snapshot.latestGrowthEvent else {
            return "还没有成长记录，去摸摸它吧"
        }
        return "最近一次：\(event.interactionType.widgetTitle)"
    }

    private var actionIcon: String {
        switch snapshot.action {
        case .eating: "fork.knife"
        case .enjoyingPet: "hand.raised.fill"
        case .playing: "circle.grid.cross.fill"
        case .sleeping: "moon.zzz.fill"
        case .seekingFood: "takeoutbag.and.cup.and.straw.fill"
        case .resting: "cloud.fill"
        case .wandering: "pawprint.fill"
        }
    }
}
