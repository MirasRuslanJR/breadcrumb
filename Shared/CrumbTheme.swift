import SwiftUI

/// Accent colors for the Live Activity. Everything except Crust is a Pro perk.
enum CrumbTheme: String, CaseIterable, Identifiable, Codable {
    case crust, blueberry, matcha, midnight

    static let storageKey = "theme"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crust: "Crust"
        case .blueberry: "Blueberry"
        case .matcha: "Matcha"
        case .midnight: "Midnight"
        }
    }

    var accent: Color {
        switch self {
        case .crust: Color(red: 0.96, green: 0.62, blue: 0.25)
        case .blueberry: Color(red: 0.47, green: 0.58, blue: 1.0)
        case .matcha: Color(red: 0.56, green: 0.82, blue: 0.42)
        case .midnight: Color(red: 0.80, green: 0.72, blue: 1.0)
        }
    }

    var isPro: Bool { self != .crust }

    static var current: CrumbTheme {
        CrumbTheme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .crust
    }
}
