import SwiftUI
import UIKit

enum PocketPalColors {
    static let background = adaptive(
        light: UIColor(red: 1.00, green: 0.98, blue: 0.93, alpha: 1),
        dark: UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1)
    )
    static let surface = adaptive(
        light: UIColor(red: 1.00, green: 1.00, blue: 0.99, alpha: 0.96),
        dark: UIColor(red: 0.16, green: 0.17, blue: 0.23, alpha: 1)
    )
    static let cream = adaptive(
        light: UIColor(red: 1.00, green: 0.86, blue: 0.58, alpha: 1),
        dark: UIColor(red: 0.75, green: 0.55, blue: 0.26, alpha: 1)
    )
    static let creamHighlight = adaptive(
        light: UIColor(red: 1.00, green: 0.95, blue: 0.78, alpha: 1),
        dark: UIColor(red: 0.90, green: 0.71, blue: 0.40, alpha: 1)
    )
    static let mint = adaptive(
        light: UIColor(red: 0.72, green: 0.91, blue: 0.79, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.47, blue: 0.38, alpha: 1)
    )
    static let peach = adaptive(
        light: UIColor(red: 1.00, green: 0.75, blue: 0.70, alpha: 1),
        dark: UIColor(red: 0.60, green: 0.32, blue: 0.32, alpha: 1)
    )
    static let sky = adaptive(
        light: UIColor(red: 0.69, green: 0.84, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.29, green: 0.42, blue: 0.62, alpha: 1)
    )
    static let lavender = adaptive(
        light: UIColor(red: 0.84, green: 0.78, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.43, green: 0.35, blue: 0.61, alpha: 1)
    )
    static let ink = adaptive(
        light: UIColor(red: 0.22, green: 0.19, blue: 0.24, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)
    )
    static let secondaryInk = adaptive(
        light: UIColor(red: 0.43, green: 0.39, blue: 0.45, alpha: 1),
        dark: UIColor(red: 0.76, green: 0.73, blue: 0.78, alpha: 1)
    )
    static let faceInk = adaptive(
        light: UIColor(red: 0.22, green: 0.17, blue: 0.16, alpha: 1),
        dark: UIColor(red: 0.16, green: 0.11, blue: 0.10, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

enum PocketPalSpacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let extraLarge: CGFloat = 28
}

enum PocketPalRadius {
    static let control: CGFloat = 16
    static let card: CGFloat = 22
    static let hero: CGFloat = 32
}
