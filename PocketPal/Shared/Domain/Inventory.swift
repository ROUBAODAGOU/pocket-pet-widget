import Foundation

struct Inventory: Codable, Equatable, Sendable {
    var snackCount: Int
    var ownedReusableItemIDs: [String]

    static let empty = Inventory(snackCount: 0, ownedReusableItemIDs: [])
    static let initial = Inventory(
        snackCount: 5,
        ownedReusableItemIDs: ["rainbow-ball"]
    )
}
