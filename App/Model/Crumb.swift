import Foundation

/// One thing you were about to do.
struct Crumb: Identifiable, Codable, Hashable {
    enum Status: String, Codable {
        /// Still on screen, waiting for you.
        case active
        /// You tapped "Got it".
        case done
        /// Faded after `CrumbStore.lifetime`.
        case expired
        /// You removed it by hand.
        case dismissed
        /// A newer breadcrumb pushed it off the trail.
        case replaced
    }

    var id = UUID()
    var text: String
    var emoji: String
    var createdAt = Date.now
    var closedAt: Date?
    var status = Status.active

    /// How long it took to get back on track, for breadcrumbs you finished.
    var timeToRecall: TimeInterval? {
        guard status == .done, let closedAt else { return nil }
        return closedAt.timeIntervalSince(createdAt)
    }
}

extension Crumb {
    /// Shown blurred behind the Insights paywall before the user has any history.
    static var samples: [Crumb] {
        let texts = ["Keys", "Charger", "Scissors", "Meds", "Keys", "Reply to Sam", "Water bottle", "Keys", "Charger", "Homework"]
        return texts.enumerated().map { index, text in
            let created = Date.now.addingTimeInterval(Double(-index * 5_400 - 600))
            var crumb = Crumb(text: text, emoji: EmojiGuesser.guess(for: text), createdAt: created)
            crumb.status = index % 4 == 3 ? .expired : .done
            crumb.closedAt = created.addingTimeInterval(Double(40 + index * 25))
            return crumb
        }
    }
}
