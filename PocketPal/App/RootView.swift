import SwiftUI

struct RootView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var router: AppRouter

    var body: some View {
        ZStack {
            PocketPalColors.background
                .ignoresSafeArea()

            switch store.contentState {
            case .loading:
                ProgressView(String(localized: "app.loading"))
                    .accessibilityIdentifier("app-loading")
            case .adoption:
                AdoptionView(store: store)
            case let .home(snapshot):
                routedContent(snapshot: snapshot)
            case let .failure(message, canRetry):
                DataRecoveryView(
                    message: message,
                    canRetry: canRetry,
                    retry: { store.refresh() }
                )
            }

#if DEBUG
            DebugRouteProbe(
                route: router.route,
                handledRequestToken: router.lastHandledRequest?.debugToken ?? "none"
            )
#endif
        }
        .tint(PocketPalColors.ink)
        .task {
            store.start()
        }
    }

    @ViewBuilder
    private func routedContent(snapshot: WidgetSnapshot) -> some View {
        switch router.route {
        case .adopt, .home:
            HomeView(store: store, snapshot: snapshot)
        case .backpack, .growth:
            RouteEntryView(
                route: router.route,
                petName: snapshot.petName,
                goHome: { router.navigate(to: .home) }
            )
        }
    }
}

#if DEBUG
private struct DebugRouteProbe: View {
    var route: AppRoute
    var handledRequestToken: String

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("内部路由状态")
            .accessibilityIdentifier(
                "root-route-\(route.rawValue)-request-\(handledRequestToken)"
            )
            .allowsHitTesting(false)
    }
}
#endif

private struct DataRecoveryView: View {
    var message: String
    var canRetry: Bool
    var retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("recovery.title", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            if canRetry {
                Button("recovery.retry", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(PocketPalSpacing.large)
        .accessibilityIdentifier("data-recovery-view")
    }
}
