import SwiftUI
import WidgetKit

struct PocketPalWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: ProjectConfiguration.widgetKind,
            provider: PocketPalTimelineProvider()
        ) { entry in
            WidgetRootView(entry: entry)
                .containerBackground(for: .widget) {
                    PocketPalColors.background
                }
        }
        .configurationDisplayName("PocketPal 桌宠")
        .description("在主屏幕看看你的小动物。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
