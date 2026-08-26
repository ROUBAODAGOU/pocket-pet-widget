import Foundation
import WidgetKit

struct PocketPalEntry: TimelineEntry, Equatable, Sendable {
    var date: Date
    var content: PocketPalWidgetContent
}
