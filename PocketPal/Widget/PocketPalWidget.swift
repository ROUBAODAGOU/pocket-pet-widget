import SwiftUI
import WidgetKit

struct ProjectStatusEntry: TimelineEntry {
    let date: Date
    let message: String
}

struct ProjectTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProjectStatusEntry {
        ProjectStatusEntry(date: .now, message: "准备领养")
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (ProjectStatusEntry) -> Void
    ) {
        completion(ProjectStatusEntry(date: .now, message: "工程已连接"))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<ProjectStatusEntry>) -> Void
    ) {
        let entry = ProjectStatusEntry(date: .now, message: "等待小动物入住")
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct PocketPalWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: ProjectConfiguration.widgetKind,
            provider: ProjectTimelineProvider()
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
    let entry: ProjectStatusEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "pawprint.fill")
                .font(.title)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("PocketPal")
                .font(.headline)

            Text(entry.message)
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
        .accessibilityLabel("PocketPal，\(entry.message)")
    }
}
