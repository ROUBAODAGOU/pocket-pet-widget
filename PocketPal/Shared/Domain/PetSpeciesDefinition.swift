import Foundation

struct PetSpeciesDefinition: Codable, Equatable, Sendable {
    var id: String
    var displayName: String
    var assetKeys: [String: String]
    var defaultTheme: String

    static let creamCat = PetSpeciesDefinition(
        id: "cream-cat",
        displayName: "奶油团子猫",
        assetKeys: ["default": "cream-cat-default"],
        defaultTheme: "macaron-cream"
    )
}
