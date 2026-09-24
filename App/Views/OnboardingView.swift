import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State var page = 0

    private static let pages: [(emoji: String, title: String, body: String)] = [
        (
            "🚪",
            "Ever walk into a room and forget why?",
            "You're not losing it. Doorways make your brain file away what you were just thinking. Psychologists call it the doorway effect."
        ),
        (
            "🎙️",
            "Say it before you go.",
            "Tap the mic and say a few words, like “grab the scissors”. That's the whole app."
        ),
        (
            "🍞",
            "It waits up top.",
            "Your breadcrumb sits in the Dynamic Island and on your Lock Screen until you tap Got it."
        ),
    ]

    private var pages: [(emoji: String, title: String, body: String)] { Self.pages }

    var body: some View {
        ZStack {
            Color.crumbBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 22) {
                            Text(pages[index].emoji)
                                .font(.system(size: 96))
                            Text(pages[index].title)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.crumbInk)
                                .multilineTextAlignment(.center)
                            Text(pages[index].body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Start")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.crumbCrust, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}
