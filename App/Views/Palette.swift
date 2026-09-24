import SwiftUI
import UIKit

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    /// Warm flour-white by day, dark rye by night.
    static let crumbBackground = Color(
        light: UIColor(red: 0.99, green: 0.96, blue: 0.91, alpha: 1),
        dark: UIColor(red: 0.07, green: 0.06, blue: 0.05, alpha: 1)
    )
    static let crumbCard = Color(
        light: .white,
        dark: UIColor(red: 0.14, green: 0.12, blue: 0.10, alpha: 1)
    )
    static let crumbInk = Color(
        light: UIColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1),
        dark: UIColor(red: 0.98, green: 0.94, blue: 0.88, alpha: 1)
    )
    static let crumbCrust = Color(red: 0.93, green: 0.52, blue: 0.19)
}

enum DurationText {
    /// "42s", "3m 10s", "1h 5m".
    static func short(_ interval: TimeInterval) -> String {
        Duration.seconds(Int(interval.rounded()))
            .formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow, maximumUnitCount: 2))
    }
}
