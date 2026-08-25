import SwiftUI

@main
struct PocketPalApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectStatusView()
        }
    }
}

private struct ProjectStatusView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                Text("PocketPal")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("project-status-title")

                Text("工程骨架已连接")
                    .font(.headline)

                Text("下一阶段会加入宠物状态、领养和互动。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .navigationTitle("项目状态")
        }
    }
}
