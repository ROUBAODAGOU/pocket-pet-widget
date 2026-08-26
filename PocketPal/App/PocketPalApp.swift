import SwiftUI

@main
@MainActor
struct PocketPalApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: AppStore

    init() {
        _store = StateObject(wrappedValue: AppComposition.makeStore())
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
        }
    }

    @ViewBuilder
    private var appContent: some View {
#if DEBUG
        if WidgetPreviewConfiguration.isEnabled {
            WidgetPreviewHarnessView(configuration: .current)
        } else {
            RootView(store: store)
        }
#else
        RootView(store: store)
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
