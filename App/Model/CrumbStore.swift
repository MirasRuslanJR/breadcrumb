import ActivityKit
import Combine
import Foundation

/// Owns every breadcrumb and keeps the Live Activity in sync with the active trail.
@MainActor
final class CrumbStore: ObservableObject {
    static let shared = CrumbStore()

    static let freeTrailLimit = 1
    static let proTrailLimit = 3
    /// After two hours a breadcrumb has almost certainly stopped mattering.
    static let lifetime: TimeInterval = 2 * 60 * 60

    @Published private(set) var crumbs: [Crumb] = []

    private let fileURL: URL

    private init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("crumbs.json")
        load()
    }

    /// Read from the cache so intents running in the background know the user's plan.
    var isPro: Bool { UserDefaults.standard.bool(forKey: ProStore.cacheKey) }

    /// Active breadcrumbs, newest first. The first one is what the Dynamic Island shows.
    var trail: [Crumb] {
        crumbs.filter { $0.status == .active }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Finished breadcrumbs, newest first.
    var history: [Crumb] {
        crumbs.filter { $0.status != .active }.sorted { $0.createdAt > $1.createdAt }
    }

    /// What the user drops most, topped up with common starters.
    var suggestions: [String] {
        var counts: [String: (text: String, count: Int)] = [:]
        for crumb in crumbs {
            counts[crumb.text.lowercased(), default: (text: crumb.text, count: 0)].count += 1
        }
        let frequent = counts.values.sorted { $0.count > $1.count }.prefix(5).map { $0.text }
        let starters = ["Keys", "Charger", "Meds", "Water bottle", "Scissors"].filter { starter in
            !frequent.contains { $0.lowercased() == starter.lowercased() }
        }
        return Array((frequent + starters).prefix(6))
    }

    var droppedThisWeek: Int {
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        return crumbs.filter { $0.createdAt > weekAgo }.count
    }

    // MARK: - Actions

    @discardableResult
    func drop(_ rawText: String) async -> Crumb? {
        let text = Self.clean(rawText)
        guard !text.isEmpty else { return nil }

        // Free keeps one breadcrumb at a time; Pro keeps a trail of three.
        let limit = isPro ? Self.proTrailLimit : Self.freeTrailLimit
        for old in trail.dropFirst(limit - 1) {
            close(old.id, as: .replaced)
        }
        let crumb = Crumb(text: text, emoji: EmojiGuesser.guess(for: text))
        crumbs.append(crumb)
        save()
        await syncLiveActivity()
        return crumb
    }

    func completeTop() async {
        guard let top = trail.first else { return }
        await complete(top.id)
    }

    func complete(_ id: UUID) async {
        close(id, as: .done)
        save()
        await syncLiveActivity()
    }

    func remove(_ id: UUID) async {
        close(id, as: .dismissed)
        save()
        await syncLiveActivity()
    }

    /// Lets breadcrumbs fade once they're too old to matter.
    func tidyUp() async {
        let now = Date.now
        for crumb in trail where now.timeIntervalSince(crumb.createdAt) > Self.lifetime {
            close(crumb.id, as: .expired)
        }
        save()
        await syncLiveActivity()
    }

    func clearHistory() {
        crumbs.removeAll { $0.status != .active }
        save()
    }

    // MARK: - Live Activity

    /// One Live Activity shows the whole trail: the newest breadcrumb up front, the rest behind it.
    func syncLiveActivity() async {
        let trail = self.trail
        let running = Activity<CrumbAttributes>.activities

        guard let top = trail.first else {
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        let theme = isPro ? CrumbTheme.current : .crust
        let state = CrumbAttributes.ContentState(
            items: trail.map { CrumbAttributes.Item(id: $0.id.uuidString, text: $0.text, emoji: $0.emoji) },
            startedAt: top.createdAt,
            themeID: theme.rawValue
        )
        let content = ActivityContent(state: state, staleDate: top.createdAt.addingTimeInterval(Self.lifetime))

        var updated = false
        for activity in running {
            if !updated, activity.activityState == .active || activity.activityState == .stale {
                await activity.update(content)
                updated = true
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        guard !updated, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            _ = try Activity<CrumbAttributes>.request(attributes: CrumbAttributes(), content: content, pushType: nil)
        } catch {
            print("Couldn't start the Live Activity: \(error)")
        }
    }

    // MARK: - Storage

    private func close(_ id: UUID, as status: Crumb.Status) {
        guard let index = crumbs.firstIndex(where: { $0.id == id }) else { return }
        crumbs[index].status = status
        crumbs[index].closedAt = .now
    }

    private static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if text.count > 80 {
            text = String(text.prefix(80))
        }
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([Crumb].self, from: data) else { return }
        crumbs = saved
    }

    private func save() {
        if crumbs.count > 1_000 {
            crumbs.removeFirst(crumbs.count - 1_000)
        }
        guard let data = try? JSONEncoder().encode(crumbs) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
