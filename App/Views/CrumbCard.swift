import SwiftUI

/// An active breadcrumb on the home screen. The newest one is big; the rest of the trail is smaller.
struct CrumbCard: View {
    let crumb: Crumb
    let isTop: Bool
    var onDone: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(crumb.emoji)
                .font(.system(size: isTop ? 44 : 28))
                .frame(width: isTop ? 72 : 48, height: isTop ? 72 : 48)
                .background(
                    Color.crumbCrust.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: isTop ? 22 : 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(isTop ? "You came here for" : "Then")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(crumb.text)
                    .font(isTop ? .system(.title2, design: .rounded).weight(.bold) : .headline)
                    .foregroundStyle(Color.crumbInk)
                    .lineLimit(2)
                Text("\(crumb.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(action: onDone) {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: isTop ? 48 : 40, height: isTop ? 48 : 40)
                    .background(Color.crumbCrust, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Got it")
        }
        .padding(isTop ? 18 : 14)
        .background(Color.crumbCard, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
        .contextMenu {
            Button("Remove", systemImage: "xmark", role: .destructive, action: onRemove)
        }
    }
}
