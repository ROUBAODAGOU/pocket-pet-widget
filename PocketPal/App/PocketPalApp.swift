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
            RootView(store: store)
                .preferredColorScheme(uiTestColorScheme)
                .onAppear {
                    store.setSceneActive(scenePhase == .active)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    store.setSceneActive(newPhase == .active)
                }
        }
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
