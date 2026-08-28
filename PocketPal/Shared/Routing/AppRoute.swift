import Foundation

enum AppRoute: String, CaseIterable, Equatable, Sendable {
    case adopt
    case home
    case backpack
    case growth

    static let safeDefault: AppRoute = .home

    init?(url: URL) {
        guard url.scheme?.lowercased() == "pocketpal",
              url.user == nil,
              url.password == nil,
              url.port == nil,
              url.query == nil,
              url.fragment == nil,
              url.path.isEmpty || url.path == "/",
              let host = url.host?.lowercased(),
              let route = AppRoute(rawValue: host) else {
            return nil
        }
        self = route
    }

    var url: URL {
        // Every case is covered by a registered, constant URL scheme.
        URL(string: "pocketpal://\(rawValue)")!
    }
}
