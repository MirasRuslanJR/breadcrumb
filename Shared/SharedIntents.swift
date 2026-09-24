import AppIntents

// These intents are compiled into both the app and the widget extension, because the
// Live Activity and the Control Center control reference them. Their `perform()` always
// runs in the app's process, so only the app build (MAIN_APP) touches app state.

/// The "Got it" button on the Live Activity.
struct CompleteCrumbIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Got It"
    static var description = IntentDescription("Clears the breadcrumb you just took care of.")

    @MainActor
    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        await CrumbStore.shared.completeTop()
        #endif
        return .result()
    }
}

/// Opens Breadcrumb already listening. Used by the Control Center / Lock Screen control.
struct OpenCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Breadcrumb Listening"
    static var description = IntentDescription("Opens Breadcrumb ready to hear what you're about to do.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        #if MAIN_APP
        CaptureRouter.shared.quickCaptureRequested = true
        #endif
        return .result()
    }
}
