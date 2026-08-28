import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var route: AppRoute
    @Published private(set) var handledURLCount = 0

    init(route: AppRoute = .safeDefault) {
        self.route = route
    }

    @discardableResult
    func handle(_ url: URL) -> Bool {
        handledURLCount += 1
        guard let parsedRoute = AppRoute(url: url) else {
            route = .safeDefault
            return false
        }
        route = parsedRoute
        return true
    }

    func navigate(to route: AppRoute) {
        self.route = route
    }
}
