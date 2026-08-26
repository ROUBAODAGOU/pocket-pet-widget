import SwiftUI
import WidgetKit

struct PocketPalWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: ProjectConfiguration.widgetKind,
            provider: PocketPalTimelineProvider()
        ) { entry in
            ProjectWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("PocketPal 桌宠")
        .description("在主屏幕看看你的小动物。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct ProjectWidgetView: View {
    let entry: PocketPalEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "pawprint.fill")
                .font(.title)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("PocketPal")
                .font(.headline)

            Text(message)
                .font(family == .systemSmall ? .caption : .body)
                .foregroundStyle(.secondary)

            if family != .systemSmall {
                Text("小、中、大三种尺寸已接入")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PocketPal，\(message)")
    }

    private var message: String {
        switch entry.content {
        case .placeholder: "准备领养"
        case .unadopted: "先去领养"
        case let .snapshot(snapshot): "\(snapshot.petName)正在\(snapshot.action.displayName)"
        case .failure: "打开 App 修复数据"
        }
    }
}
