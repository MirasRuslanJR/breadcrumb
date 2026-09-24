import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: CrumbStore
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    /// Free keeps a week of history; Pro keeps everything.
    private var visible: [Crumb] {
        guard !pro.isPro else { return store.history }
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        return store.history.filter { $0.createdAt > weekAgo }
    }

    private var days: [DayGroup] {
        let groups = Dictionary(grouping: visible) { Calendar.current.startOfDay(for: $0.createdAt) }
        return groups.keys.sorted(by: >).map { DayGroup(day: $0, crumbs: groups[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    InsightsView()
                } label: {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
            }

            ForEach(days) { group in
                Section(group.day.formatted(.dateTime.weekday(.wide).month().day())) {
                    ForEach(group.crumbs) { crumb in
                        HistoryRow(crumb: crumb)
                    }
                }
            }

            let hidden = store.history.count - visible.count
            if hidden > 0 {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("\(hidden) older breadcrumbs. Pro keeps them all.", systemImage: "lock.fill")
                    }
                }
            }
        }
        .overlay {
            if store.history.isEmpty {
                ContentUnavailableView(
                    "Nothing here yet",
                    systemImage: "leaf",
                    description: Text("Breadcrumbs you finish show up here.")
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.crumbBackground)
        .navigationTitle("History")
        .toolbar(.visible, for: .navigationBar)
        .paywallSheet(isPresented: $showPaywall)
    }
}

private struct DayGroup: Identifiable {
    let day: Date
    let crumbs: [Crumb]
    var id: Date { day }
}

struct HistoryRow: View {
    let crumb: Crumb

    var body: some View {
        HStack(spacing: 12) {
            Text(crumb.emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(crumb.text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.crumbInk)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: icon.name)
                .foregroundStyle(icon.color)
        }
    }

    private var detail: String {
        let time = crumb.createdAt.formatted(date: .omitted, time: .shortened)
        switch crumb.status {
        case .done:
            guard let recall = crumb.timeToRecall else { return time }
            return "\(time) · done in \(DurationText.short(recall))"
        case .expired: return "\(time) · faded after 2h"
        case .replaced: return "\(time) · swapped for a newer one"
        case .dismissed: return "\(time) · removed"
        case .active: return "\(time) · still waiting"
        }
    }

    private var icon: (name: String, color: Color) {
        switch crumb.status {
        case .done: ("checkmark.circle.fill", .green)
        case .expired: ("hourglass", .orange)
        case .replaced: ("arrow.triangle.2.circlepath", .secondary)
        case .dismissed: ("xmark.circle", .secondary)
        case .active: ("dot.radiowaves.left.and.right", Color.crumbCrust)
        }
    }
}
