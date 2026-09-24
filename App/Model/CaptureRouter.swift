import Combine

/// Lets intents that open the app (Control Center, Action Button) ask the home screen to start listening.
@MainActor
final class CaptureRouter: ObservableObject {
    static let shared = CaptureRouter()

    @Published var quickCaptureRequested = false
}
