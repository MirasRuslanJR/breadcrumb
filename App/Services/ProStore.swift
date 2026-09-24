import Combine
import Foundation
import RevenueCat

/// Tracks whether the user has Breadcrumb Pro, via RevenueCat.
@MainActor
final class ProStore: ObservableObject {
    static let entitlementID = "pro"
    /// Cached so App Intents running in the background can check Pro without a network call.
    static let cacheKey = "isPro"

    @Published private(set) var isPro = UserDefaults.standard.bool(forKey: cacheKey)

    /// Injected at build time (see project.yml). Empty when the build has no key.
    static var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
              !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return key
    }

    static func configureRevenueCat() {
        guard let apiKey else {
            print("No RevenueCat key in this build, so purchases are turned off.")
            return
        }
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        // RevenueCat deliberately crashes release builds that use a Test Store key.
        guard !apiKey.hasPrefix("test_") else { return }
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

    init() {
        guard Purchases.isConfigured else { return }
        Task { await listen() }
    }

    func refresh() async {
        guard Purchases.isConfigured,
              let info = try? await Purchases.shared.customerInfo() else { return }
        apply(info)
    }

    func restore() async throws {
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
    }

    func apply(_ info: CustomerInfo) {
        let active = info.entitlements[Self.entitlementID]?.isActive == true
        isPro = active
        UserDefaults.standard.set(active, forKey: Self.cacheKey)
    }

    private func listen() async {
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }
}
