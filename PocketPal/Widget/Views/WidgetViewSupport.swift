import SwiftUI

enum WidgetStatusKind: String, CaseIterable, Identifiable {
    case mood
    case hunger
    case intimacy
    case coins

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mood: "心情"
        case .hunger: "饥饿"
        case .intimacy: "亲密度"
        case .coins: "金币"
        }
    }

    var compactTitle: String {
        switch self {
        case .mood: "心情"
        case .hunger: "饥饿"
        case .intimacy: "亲密"
        case .coins: "金币"
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

    func value(in snapshot: WidgetSnapshot) -> Int {
        switch self {
        case .mood: snapshot.mood
        case .hunger: snapshot.hunger
        case .intimacy: snapshot.intimacy
        case .coins: snapshot.coins
        }
    }
}

struct WidgetCompactMetric: View {
    var kind: WidgetStatusKind
    var snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: kind.icon)
                .font(.caption2)
                .foregroundStyle(PocketPalColors.faceInk)
                .frame(width: 16, height: 16)
                .background(kind.tint, in: Circle())
                .accessibilityHidden(true)

            Text(kind.compactTitle)
                .font(.caption2)
                .foregroundStyle(PocketPalColors.secondaryInk)
                .lineLimit(1)

            Spacer(minLength: 1)

            Text(kind.value(in: snapshot), format: .number)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(PocketPalColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title)，\(kind.value(in: snapshot))")
    }
}

struct WidgetTinyMetric: View {
    var kind: WidgetStatusKind
    var snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 0) {
            Text(kind.compactTitle)
                .font(.caption2)
                .foregroundStyle(PocketPalColors.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            HStack(spacing: 3) {
                Image(systemName: kind.icon)
                    .font(.caption2)
                    .foregroundStyle(PocketPalColors.faceInk)
                    .frame(width: 17, height: 17)
                    .background(kind.tint, in: Circle())
                    .accessibilityHidden(true)
                Text(kind.value(in: snapshot), format: .number)
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(PocketPalColors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(PocketPalColors.ink)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title)，\(kind.value(in: snapshot))")
    }
}

struct WidgetMetricCard: View {
    var kind: WidgetStatusKind
    var snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: PocketPalSpacing.small) {
            Image(systemName: kind.icon)
                .font(.caption.bold())
                .foregroundStyle(PocketPalColors.faceInk)
                .frame(width: 24, height: 24)
                .background(kind.tint, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(kind.title)
                    .font(.caption2)
                    .foregroundStyle(PocketPalColors.secondaryInk)
                    .lineLimit(1)
                Text(kind.value(in: snapshot), format: .number)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(PocketPalColors.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(7)
        .background(PocketPalColors.surface.opacity(0.88), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title)，\(kind.value(in: snapshot))")
    }
}

struct WidgetProgressMetric: View {
    var kind: WidgetStatusKind
    var snapshot: WidgetSnapshot

    var body: some View {
        let value = kind.value(in: snapshot)
        VStack(spacing: 3) {
            HStack {
                Label(kind.title, systemImage: kind.icon)
                    .font(.caption)
                    .foregroundStyle(PocketPalColors.secondaryInk)
                Spacer(minLength: 4)
                Text(value, format: .number)
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(PocketPalColors.ink)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PocketPalColors.ink.opacity(0.09))
                    Capsule()
                        .fill(kind.tint)
                        .frame(width: proxy.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.title)，\(value)，满值一百")
    }
}

struct WidgetActionStrip: View {
    var snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 6) {
            ForEach(PetInteraction.allCases, id: \.self) { interaction in
                WidgetInteractionControl(
                    interaction: interaction,
                    snapshot: snapshot,
                    style: .strip
                )
            }
        }
    }
}

extension WidgetSnapshot {
    var moodMessage: String {
        switch action {
        case .eating: "这口饼干太香啦！"
        case .enjoyingPet: "再摸一下也可以哦"
        case .playing: "今天也要尽情玩！"
        case .sleeping: "做个软绵绵的好梦"
        case .seekingFood: "肚子在咕咕叫啦"
        case .resting: "陪我安静待一会儿吧"
        case .wandering: "正在家里慢悠悠巡视"
        }
    }
}

extension PetInteraction {
    var widgetTitle: String {
        switch self {
        case .feed: "喂食"
        case .pet: "抚摸"
        case .play: "玩耍"
        }
    }

    var widgetIcon: String {
        switch self {
        case .feed: "star.fill"
        case .pet: "hand.raised.fill"
        case .play: "circle.grid.cross.fill"
        }
    }

    var widgetTint: Color {
        switch self {
        case .feed: PocketPalColors.cream
        case .pet: PocketPalColors.peach
        case .play: PocketPalColors.sky
        }
    }
}
