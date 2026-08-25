import WidgetKit

struct WidgetCenterRefreshNotifier: WidgetRefreshNotifying {
    func reloadPetWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: ProjectConfiguration.widgetKind)
    }
}
