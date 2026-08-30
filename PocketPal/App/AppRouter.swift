import Combine
import Foundation

enum HandledRouteRequest: Equatable, Sendable {
    case route(AppRoute)
    case invalid

    var debugToken: String {
        switch self {
        case let .route(route): route.rawValue
        case .invalid: "invalid"
        }
    }
}

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var route: AppRoute
    @Published private(set) var lastHandledRequest: HandledRouteRequest?

    init(route: AppRoute = .safeDefault) {
        self.route = route
        lastHandledRequest = nil
    }

    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard let parsedRoute = AppRoute(url: url) else {
            route = .safeDefault
            lastHandledRequest = .invalid
            return false
        }
        route = parsedRoute
        lastHandledRequest = .route(parsedRoute)
        return true
    }

    func navigate(to route: AppRoute) {
        self.route = route
    }
}
