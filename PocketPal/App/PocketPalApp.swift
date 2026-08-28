import SwiftUI

@main
@MainActor
struct PocketPalApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: AppStore
    @StateObject private var router: AppRouter

    init() {
        _store = StateObject(wrappedValue: AppComposition.makeStore())
        _router = StateObject(wrappedValue: AppRouter())
    }

    var body: some Scene {
        WindowGroup {
            appContent
                .preferredColorScheme(uiTestColorScheme)
                .onAppear {
                    store.setSceneActive(scenePhase == .active)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    store.setSceneActive(newPhase == .active)
                }
                .onOpenURL { url in
                    router.handle(url)
                }
        }
    }

    @ViewBuilder
    private var appContent: some View {
#if DEBUG
        if WidgetPreviewConfiguration.isEnabled {
            WidgetPreviewHarnessView(configuration: .current)
        } else {
            RootView(store: store, router: router)
        }
#else
        RootView(store: store, router: router)
#endif
    }

    private var uiTestColorScheme: ColorScheme? {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--pocketpal-ui-test-dark-mode") {
            return .dark
        }
#endif
        return nil
    }
}
