import SwiftUI
import WidgetKit

struct WidgetRootView: View {
    var entry: PocketPalEntry
    var familyOverride: WidgetFamily?

    @Environment(\.widgetFamily) private var environmentFamily
    @Environment(\.redactionReasons) private var redactionReasons

    var body: some View {
        ZStack {
            decorativeBackground

            if redactionReasons.contains(.privacy) {
                WidgetProtectedStateView(family: family)
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var family: WidgetFamily {
        familyOverride ?? environmentFamily
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .placeholder:
            WidgetPlaceholderStateView(family: family)
                .redacted(reason: .placeholder)
        case .unadopted:
            WidgetMessageStateView(
                family: family,
                action: .wandering,
                title: "先去领养",
                message: "打开 PocketPal，给小伙伴取个名字",
                systemImage: "heart.circle.fill"
            )
        case let .snapshot(snapshot):
            snapshotView(snapshot)
                .privacySensitive()
        case .failure:
            WidgetMessageStateView(
                family: family,
                action: .resting,
                title: "暂时读不到宠物",
                message: "打开 App 修复本地数据",
                systemImage: "externaldrive.badge.exclamationmark"
            )
        }
    }

    @ViewBuilder
    private func snapshotView(_ snapshot: WidgetSnapshot) -> some View {
        switch family {
        case .systemSmall:
            SmallPetWidgetView(snapshot: snapshot)
        case .systemMedium:
            MediumPetWidgetView(snapshot: snapshot)
        case .systemLarge:
            LargePetWidgetView(snapshot: snapshot)
        default:
            MediumPetWidgetView(snapshot: snapshot)
        }
    }

    private var decorativeBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(PocketPalColors.mint.opacity(0.22))
                    .frame(width: proxy.size.width * 0.62)
                    .offset(x: -proxy.size.width * 0.37, y: -proxy.size.height * 0.34)
                Circle()
                    .fill(PocketPalColors.lavender.opacity(0.18))
                    .frame(width: proxy.size.width * 0.48)
                    .offset(x: proxy.size.width * 0.42, y: proxy.size.height * 0.38)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct WidgetPlaceholderStateView: View {
    var family: WidgetFamily

    var body: some View {
        HStack(spacing: 8) {
            PetAvatarView(action: .wandering, size: family == .systemLarge ? 130 : 74)
            VStack(alignment: .leading, spacing: 8) {
                Text("奶糖正在闲逛")
                    .font(.headline)
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .frame(maxWidth: .infinity)
                        .frame(height: 10)
                }
            }
        }
        .accessibilityLabel("PocketPal 小组件加载占位")
    }
}

private struct WidgetMessageStateView: View {
    var family: WidgetFamily
    var action: PetAction
    var title: String
    var message: String
    var systemImage: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isSmall = family == .systemSmall
        Group {
            if isSmall, dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: 5) {
                    PetAvatarView(action: action, size: 38)
                    titleAndMessage
                }
            } else if isSmall {
                VStack(spacing: 5) {
                    PetAvatarView(action: action, size: 72)
                    titleAndMessage
                }
            } else {
                HStack(spacing: 16) {
                    PetAvatarView(action: action, size: family == .systemLarge ? 142 : 92)
                    titleAndMessage
                }
            }
        }
        .dynamicTypeSize(
            dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(message)")
    }

    private var titleAndMessage: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(PocketPalColors.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text(message)
                .font(.caption)
                .foregroundStyle(PocketPalColors.secondaryInk)
                .lineLimit(family == .systemLarge ? 3 : 2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WidgetProtectedStateView: View {
    var family: WidgetFamily

    var body: some View {
        WidgetMessageStateView(
            family: family,
            action: .sleeping,
            title: "宠物状态已保护",
            message: "解锁设备后查看名字和数值",
            systemImage: "lock.fill"
        )
        .accessibilityLabel("PocketPal 宠物状态已保护，解锁设备后查看")
    }
}
