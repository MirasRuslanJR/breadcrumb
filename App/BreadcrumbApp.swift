import SwiftUI

@main
struct BreadcrumbApp: App {
    @StateObject private var store = CrumbStore.shared
    @StateObject private var pro = ProStore()
    @StateObject private var router = CaptureRouter.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ProStore.configureRevenueCat()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(pro)
                .environmentObject(router)
                .tint(Color.crumbCrust)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await store.tidyUp()
                await pro.refresh()
            }
        }
    }
}

struct RootView: View {
    @AppStorage("didOnboard") private var didOnboard = false

    var body: some View {
        if didOnboard {
            HomeView()
        } else {
            OnboardingView {
                withAnimation(.easeInOut) { didOnboard = true }
            }
        }
    }
}
