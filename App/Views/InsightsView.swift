import Charts
import SwiftUI

/// Pro: patterns in what you forget and when.
struct InsightsView: View {
    @EnvironmentObject private var store: CrumbStore
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    /// Free users see a blurred preview; sample data keeps it from looking empty.
    private var crumbs: [Crumb] {
        store.crumbs.isEmpty && !pro.isPro ? Crumb.samples : store.crumbs
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                stats
                hourChart
                mostDropped
            }
            .padding(20)
            .blur(radius: pro.isPro ? 0 : 10)
            .allowsHitTesting(pro.isPro)
        }
        .overlay {
            if !pro.isPro {
                locked
            }
        }
        .background(Color.crumbBackground)
        .navigationTitle("Insights")
        .toolbar(.visible, for: .navigationBar)
        .paywallSheet(isPresented: $showPaywall)
    }

    // MARK: - Sections

    private var stats: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(value: "\(crumbs.count)", label: "thoughts saved")
            StatTile(value: recallRate, label: "followed through")
            StatTile(value: averageRecall, label: "average time to do it")
            StatTile(value: busiestHour, label: "when your mind wanders most")
        }
    }

    private var hourChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When you drop breadcrumbs")
                .font(.headline)
                .foregroundStyle(Color.crumbInk)
            Chart(byHour) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Breadcrumbs", item.count)
                )
                .foregroundStyle(Color.crumbCrust.gradient)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(Self.hourLabel(hour))
                        }
                    }
                }
            }
            .frame(height: 150)
        }
        .padding(16)
        .background(Color.crumbCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var mostDropped: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What slips your mind most")
                .font(.headline)
                .foregroundStyle(Color.crumbInk)
            ForEach(topItems) { item in
                HStack {
                    Text(item.emoji)
                    Text(item.text)
                        .foregroundStyle(Color.crumbInk)
                    Spacer()
                    Text("×\(item.count)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.crumbCrust)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.crumbCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var locked: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.crumbCrust)
            Text("See what you forget most")
                .font(.title3.bold())
                .foregroundStyle(Color.crumbInk)
            Text("Pro shows your patterns: when you lose your train of thought, what slips most, and how fast you get back on track.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Unlock Insights") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.crumbCrust)
            .padding(.top, 4)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(24)
    }

    // MARK: - Numbers

    private var recallRate: String {
        let finished = crumbs.filter { $0.status == .done || $0.status == .expired }
        guard !finished.isEmpty else { return "–" }
        let done = finished.filter { $0.status == .done }.count
        return "\(Int((Double(done) / Double(finished.count) * 100).rounded()))%"
    }

    private var averageRecall: String {
        let times = crumbs.compactMap(\.timeToRecall)
        guard !times.isEmpty else { return "–" }
        return DurationText.short(times.reduce(0, +) / Double(times.count))
    }

    private var byHour: [HourCount] {
        let counts = Dictionary(grouping: crumbs) { Calendar.current.component(.hour, from: $0.createdAt) }
        return (0..<24).map { HourCount(hour: $0, count: counts[$0]?.count ?? 0) }
    }

    private var busiestHour: String {
        guard let top = byHour.max(by: { $0.count < $1.count }), top.count > 0 else { return "–" }
        return Self.hourLabel(top.hour)
    }

    private var topItems: [TopItem] {
        let groups = Dictionary(grouping: crumbs) { $0.text.lowercased() }
        return groups.values
            .map { TopItem(text: $0[0].text, emoji: $0[0].emoji, count: $0.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    private static func hourLabel(_ hour: Int) -> String {
        guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) else { return "\(hour)" }
        return date.formatted(.dateTime.hour())
    }
}

private struct HourCount: Identifiable {
    let hour: Int
    let count: Int
    var id: Int { hour }
}

private struct TopItem: Identifiable {
    let text: String
    let emoji: String
    let count: Int
    var id: String { text }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(Color.crumbInk)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.crumbCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
