import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: CrumbStore
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var router: CaptureRouter
    @StateObject private var speech = SpeechCapture()

    @State private var draft = ""
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var toast: Toast?
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crumbBackground.ignoresSafeArea()

                VStack(spacing: 18) {
                    header
                    Spacer(minLength: 0)
                    if speech.state == .listening {
                        listening
                    } else if store.trail.isEmpty {
                        emptyState
                    } else {
                        trail
                    }
                    Spacer(minLength: 0)
                    composer
                    suggestions
                    historyLink
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: speech.state)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.trail.map(\.id))
            }
            .overlay(alignment: .top) { toastView }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(pro)
            }
            .paywallSheet(isPresented: $showPaywall)
        }
        .onAppear {
            speech.onFinished = { text in drop(text) }
            startQuickCaptureIfRequested()
        }
        .onChange(of: router.quickCaptureRequested) { _, _ in
            startQuickCaptureIfRequested()
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 14) {
            Text("Breadcrumb")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.crumbInk)
            Spacer()
            if !pro.isPro {
                Button {
                    showPaywall = true
                } label: {
                    Label("Pro", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.crumbCrust.opacity(0.16), in: Capsule())
                }
                .foregroundStyle(Color.crumbCrust)
            }
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Color.crumbInk.opacity(0.55))
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🍞")
                .font(.system(size: 64))
            Text("What are you about to do?")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Color.crumbInk)
                .multilineTextAlignment(.center)
            Text("Say it before you walk through the door.\nIt'll wait for you at the top of your screen.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var listening: some View {
        VStack(spacing: 12) {
            Text("Listening…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.crumbCrust)
            Text(speech.transcript.isEmpty ? "“grab the scissors”" : speech.transcript)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(speech.transcript.isEmpty ? Color.crumbInk.opacity(0.25) : Color.crumbInk)
                .multilineTextAlignment(.center)
                .animation(.easeOut(duration: 0.15), value: speech.transcript)
        }
        .transition(.opacity)
    }

    private var trail: some View {
        VStack(spacing: 12) {
            ForEach(Array(store.trail.enumerated()), id: \.element.id) { index, crumb in
                CrumbCard(crumb: crumb, isTop: index == 0) {
                    complete(crumb)
                } onRemove: {
                    Task { await store.remove(crumb.id) }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 12) {
            TextField("Or type it…", text: $draft)
                .focused($typing)
                .submitLabel(.done)
                .onSubmit { drop(draft) }
                .padding(.horizontal, 20)
                .frame(height: 56)
                .background(Color.crumbCard, in: Capsule())
                .foregroundStyle(Color.crumbInk)
            MicButton(isListening: speech.state == .listening) {
                toggleListening()
            }
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.suggestions, id: \.self) { text in
                    Button {
                        drop(text)
                    } label: {
                        Text("\(EmojiGuesser.guess(for: text)) \(text)")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.crumbCard, in: Capsule())
                    }
                    .foregroundStyle(Color.crumbInk)
                }
            }
        }
        .scrollClipDisabled()
    }

    private var historyLink: some View {
        NavigationLink {
            HistoryView()
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text(weeklySummary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .font(.subheadline)
            .foregroundStyle(Color.crumbInk.opacity(0.65))
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            HStack(spacing: 10) {
                Text(toast.message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.crumbInk)
                if toast.offersPro {
                    Button("See Pro") {
                        self.toast = nil
                        showPaywall = true
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.crumbCrust)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
            .padding(.top, 52)
            .padding(.horizontal, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
            .id(toast.id)
        }
    }

    private var weeklySummary: String {
        switch store.droppedThisWeek {
        case 0: "Your breadcrumbs show up here"
        case 1: "1 thought saved this week"
        case let count: "\(count) thoughts saved this week"
        }
    }

    // MARK: - Actions

    private func toggleListening() {
        typing = false
        if speech.state == .listening {
            speech.stop()
            return
        }
        Task {
            await speech.start()
            if speech.state == .denied {
                show(Toast(message: "Turn on Microphone and Speech for Breadcrumb in Settings."))
            } else if speech.state == .unavailable {
                show(Toast(message: "Speech isn't available right now. Try typing instead."))
            }
        }
    }

    private func startQuickCaptureIfRequested() {
        guard router.quickCaptureRequested else { return }
        router.quickCaptureRequested = false
        Task { await speech.start() }
    }

    private func drop(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let replacesOld = !pro.isPro && !store.trail.isEmpty
        draft = ""
        typing = false
        Task {
            guard await store.drop(text) != nil else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if replacesOld {
                show(Toast(message: "Swapped for the new one. Pro keeps a trail of 3.", offersPro: true))
            } else {
                show(Toast(message: "Pinned to the top of your screen. Go!"))
            }
        }
    }

    private func complete(_ crumb: Crumb) {
        Task {
            await store.complete(crumb.id)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            let elapsed = Date.now.timeIntervalSince(crumb.createdAt)
            show(Toast(message: "Done in \(DurationText.short(elapsed)). Nice."))
        }
    }

    private func show(_ newToast: Toast) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { toast = newToast }
        Task {
            try? await Task.sleep(for: .seconds(newToast.offersPro ? 4 : 2.5))
            if toast?.id == newToast.id {
                withAnimation(.easeOut) { toast = nil }
            }
        }
    }
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    var message: String
    var offersPro = false
}
