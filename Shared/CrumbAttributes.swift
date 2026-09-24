import ActivityKit
import Foundation

/// The Live Activity that shows your current breadcrumb in the Dynamic Island and on the Lock Screen.
struct CrumbAttributes: ActivityAttributes {
    struct Item: Codable, Hashable {
        var id: String
        var text: String
        var emoji: String
    }

    struct ContentState: Codable, Hashable {
        /// Newest first. The first item is the one on screen; the rest are the trail behind it.
        var items: [Item]
        var startedAt: Date
        var themeID: String

        var top: Item {
            items.first ?? Item(id: "", text: "", emoji: "🍞")
        }
    }

    var name: String = "trail"
}
