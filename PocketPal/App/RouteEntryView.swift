import SwiftUI

struct RouteEntryView: View {
    var route: AppRoute
    var petName: String
    var goHome: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: PocketPalSpacing.large) {
                Spacer(minLength: PocketPalSpacing.large)

                PetAvatarView(action: .wandering, size: 168)

                VStack(spacing: PocketPalSpacing.small) {
                    Label(title, systemImage: systemImage)
                        .font(.title.bold())
                        .foregroundStyle(PocketPalColors.ink)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(PocketPalColors.secondaryInk)
                        .multilineTextAlignment(.center)
                }

                Button(action: goHome) {
                    Label("返回家园", systemImage: "house.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("route-entry-home-button")

                Spacer(minLength: PocketPalSpacing.large)
            }
            .padding(PocketPalSpacing.large)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(PocketPalColors.background.ignoresSafeArea())
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var title: String {
        switch route {
        case .backpack: "背包入口"
        case .growth: "成长入口"
        case .adopt, .home: "家园入口"
        }
    }

    private var message: String {
        switch route {
        case .backpack:
            "这里会管理 \(petName) 的星星饼干和彩虹球。完整背包将在下一阶段接入。"
        case .growth:
            "这里会记录 \(petName) 最近的互动和亲密成长。完整时间线将在下一阶段接入。"
        case .adopt, .home:
            "回到 \(petName) 的家园继续互动。"
        }
    }

    private var systemImage: String {
        switch route {
        case .backpack: "backpack.fill"
        case .growth: "chart.line.uptrend.xyaxis"
        case .adopt, .home: "house.fill"
        }
    }

    private var accessibilityIdentifier: String {
        switch route {
        case .backpack: "backpack-route-entry"
        case .growth: "growth-route-entry"
        case .adopt, .home: "home-route-entry"
        }
    }
}
