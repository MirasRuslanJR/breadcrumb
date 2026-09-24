import AppIntents

/// Drops a breadcrumb without opening the app. Great on the Action Button:
/// press it, say what you're doing, and it's pinned to the Dynamic Island.
struct DropCrumbIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Drop a Breadcrumb"
    static var description = IntentDescription("Pins what you're about to do to the top of your screen, so you don't lose it on the way.")

    @Parameter(title: "What for?", requestValueDialog: IntentDialog("What are you about to do?"))
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        await CrumbStore.shared.drop(text)
        return .result(dialog: "Got it. Go get it.")
    }
}

struct BreadcrumbShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DropCrumbIntent(),
            phrases: [
                "Drop a \(.applicationName)",
                "Leave a \(.applicationName)",
            ],
            shortTitle: "Drop a Breadcrumb",
            systemImageName: "mic.fill"
        )
        AppShortcut(
            intent: CompleteCrumbIntent(),
            phrases: [
                "Clear my \(.applicationName)",
                "I found it with \(.applicationName)",
            ],
            shortTitle: "Got It",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
