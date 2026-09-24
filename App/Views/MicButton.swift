import SwiftUI

/// Tap to talk, tap again (or just stop talking) to finish.
struct MicButton: View {
    let isListening: Bool
    let action: () -> Void

    @State var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isListening {
                    Circle()
                        .stroke(Color.crumbCrust.opacity(0.45), lineWidth: 3)
                        .scaleEffect(pulse ? 1.5 : 1)
                        .opacity(pulse ? 0 : 1)
                }
                Circle()
                    .fill(isListening ? Color.red : Color.crumbCrust)
                    .shadow(color: Color.crumbCrust.opacity(0.35), radius: 10, y: 4)
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: isListening)
        .onChange(of: isListening) { _, listening in
            pulse = false
            guard listening else { return }
            withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
        .accessibilityLabel(isListening ? "Stop listening" : "Say a breadcrumb")
    }
}
