import RevenueCat
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CrumbStore
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(CrumbTheme.storageKey) private var themeID = CrumbTheme.crust.rawValue

    @State private var showPaywall = false
    @State private var restoreMessage: String?
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if pro.isPro {
                        Label("Breadcrumb Pro is on", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.crumbCrust)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Get Breadcrumb Pro", systemImage: "sparkles")
                        }
                    }
                    Button("Restore purchases") {
                        Task { await restore() }
                    }
                } header: {
                    Text("Pro")
                } footer: {
                    Text("Pro keeps a trail of 3 breadcrumbs at once, your full history, Insights, and Island colors.")
                }

                Section("Island color") {
                    ForEach(CrumbTheme.allCases) { theme in
                        Button {
                            select(theme)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 22, height: 22)
                                Text(theme.name)
                                    .foregroundStyle(Color.crumbInk)
                                Spacer()
                                if theme.rawValue == themeID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.crumbCrust)
                                } else if theme.isPro && !pro.isPro {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    TipRow(
                        icon: "button.horizontal.top.press",
                        title: "Action Button",
                        text: "Settings → Action Button → Shortcut → Drop a Breadcrumb. Press it, say it, done."
                    )
                    TipRow(
                        icon: "switch.2",
                        title: "Control Center or Lock Screen",
                        text: "Edit your controls → Add a Control → Breadcrumb."
                    )
                    TipRow(
                        icon: "waveform",
                        title: "Siri",
                        text: "Say “Drop a Breadcrumb”."
                    )
                } header: {
                    Text("Drop breadcrumbs faster")
                }

                Section("Why this works") {
                    Text("Walking through a doorway makes your brain close one “scene” and start another, so the thought you were holding gets filed away. Psychologists call it the doorway effect. Saying what you're doing out loud and keeping it in sight carries the thought across.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Clear history", role: .destructive) {
                        confirmClear = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.crumbBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Clear all finished breadcrumbs?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) {
                    store.clearHistory()
                }
            }
            .alert(
                "Restore purchases",
                isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })
            ) {
                Button("OK") {}
            } message: {
                Text(restoreMessage ?? "")
            }
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    private func select(_ theme: CrumbTheme) {
        guard !theme.isPro || pro.isPro else {
            showPaywall = true
            return
        }
        themeID = theme.rawValue
        Task { await store.syncLiveActivity() }
    }

    private func restore() async {
        guard Purchases.isConfigured else {
            restoreMessage = "Purchases aren't set up in this build."
            return
        }
        do {
            try await pro.restore()
            restoreMessage = pro.isPro ? "Pro is back. Welcome!" : "No purchases found for this account."
        } catch {
            restoreMessage = error.localizedDescription
        }
    }
}

private struct TipRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.crumbCrust)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.crumbInk)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
