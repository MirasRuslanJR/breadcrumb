import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Shows your current breadcrumb in the Dynamic Island and on the Lock Screen.
struct CrumbLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CrumbAttributes.self) { context in
            LockScreenCrumbView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(Color.black.opacity(0.78))
                .activitySystemActionForegroundColor(Self.accent(context.state))
        } dynamicIsland: { context in
            let state = context.state
            let accent = Self.accent(state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(state.top.emoji)
                        .font(.system(size: 40))
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 56)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.isStale ? "Still need this?" : "You came here for")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(state.top.text)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if state.items.count > 1 {
                            Text("Then: \(state.items[1].emoji) \(state.items[1].text)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(intent: CompleteCrumbIntent()) {
                            Label("Got it", systemImage: "checkmark")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(accent)
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Text(state.top.emoji)
            } compactTrailing: {
                Text(state.top.text)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            } minimal: {
                Text(state.top.emoji)
            }
            .keylineTint(accent)
        }
    }

    static func accent(_ state: CrumbAttributes.ContentState) -> Color {
        (CrumbTheme(rawValue: state.themeID) ?? .crust).accent
    }
}

private struct LockScreenCrumbView: View {
    let state: CrumbAttributes.ContentState
    let isStale: Bool

    var body: some View {
        let accent = CrumbLiveActivity.accent(state)
        HStack(spacing: 14) {
            Text(state.top.emoji)
                .font(.system(size: 36))
                .frame(width: 58, height: 58)
                .background(accent.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(isStale ? "Still need this?" : "You came here for")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(state.top.text)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if state.items.count > 1 {
                    Text("+\(state.items.count - 1) more in your trail")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(accent)
                }
            }

            Spacer(minLength: 0)

            Button(intent: CompleteCrumbIntent()) {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Got it")
        }
        .padding(16)
    }
}
