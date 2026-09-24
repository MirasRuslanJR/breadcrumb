import RevenueCat
import RevenueCatUI
import SwiftUI

/// Presents the RevenueCat paywall configured in the dashboard (offering "default").
struct PaywallSheet: ViewModifier {
    @Binding var isPresented: Bool
    @EnvironmentObject var pro: ProStore

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            if Purchases.isConfigured {
                PaywallView(displayCloseButton: true)
                    .onPurchaseCompleted { info in
                        pro.apply(info)
                        isPresented = false
                    }
                    .onRestoreCompleted { info in
                        pro.apply(info)
                        if pro.isPro {
                            isPresented = false
                        }
                    }
            } else {
                ContentUnavailableView(
                    "Purchases aren't set up",
                    systemImage: "cart.badge.questionmark",
                    description: Text("This build has no RevenueCat key. See the README to add one.")
                )
                .presentationDetents([.medium])
            }
        }
    }
}

extension View {
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallSheet(isPresented: isPresented))
    }
}
