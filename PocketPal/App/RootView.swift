import SwiftUI

struct RootView: View {
    @ObservedObject var store: AppStore

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
                HomeView(store: store, snapshot: snapshot)
            case let .failure(message, canRetry):
                DataRecoveryView(
                    message: message,
                    canRetry: canRetry,
                    retry: { store.refresh() }
                )
            }
        }
        .tint(PocketPalColors.ink)
        .task {
            store.start()
        }
    }
}

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
