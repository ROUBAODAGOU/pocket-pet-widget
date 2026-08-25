import Foundation

protocol WidgetRefreshNotifying: Sendable {
    func reloadPetWidget()
}

struct NoOpWidgetRefreshNotifier: WidgetRefreshNotifying {
    func reloadPetWidget() {}
}
