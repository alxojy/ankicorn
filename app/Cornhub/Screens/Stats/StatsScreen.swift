import Charts
import SwiftUI
import UIKit

/// Stats tab: native charts from the engine's `graphs` method; Anki's own page is one tap away as "More stats".
struct StatsScreen: View {
    let backend: Backend?

    var body: some View {
        if let backend {
            StatsContent(model: StatsModel(backend: backend), backend: backend)
        } else {
            PlaceholderScreen(title: "Stats", symbol: "chart.bar", message: "Open a collection to see your stats.")
        }
    }
}

private struct StatsContent: View {
    @State var model: StatsModel
    let backend: Backend
    @State private var showMore = false
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    deckPicker
                    rangeChips
                    switch model.phase {
                    case .loading:
                        ProgressView("Loading stats")
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .foregroundStyle(Theme.text2)
                    case .empty:
                        ContentUnavailableView(
                            "No reviews yet", systemImage: "chart.bar",
                            description: Text("Study a few cards and your stats will show up here."))
                    case .failed(let message):
                        ContentUnavailableView {
                            Label("Could not load stats", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(message)
                        } actions: {
                            Button("Try again") { Task { await model.load() } }
                                .frame(minHeight: Theme.minTarget)
                        }
                    case .ready:
                        Group {
                            hero
                            activity
                            forecast
                        }
                        .id(model.range)
                        .transition(.opacity)
                    }
                    moreStats
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .background(Theme.bg.ignoresSafeArea())
            .tabBarScroll()
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await model.load()
            consumeDeckRequest()
        }
        .sheet(isPresented: $showMore) { AnkiWebSheet(page: .graphs, backend: backend) }
    }

    /// Applies the deck a screen asked Stats to filter to (the deck overview's Coming up card).
    private func consumeDeckRequest() {
        guard let id = appState.statsDeckID else { return }
        appState.statsDeckID = nil
        if let match = model.decks.first(where: { $0.id == id }) { model.deck = match }
    }

    private var deckPicker: some View {
        HStack {
            Menu {
                Button { model.deck = nil } label: {
                    if model.deck == nil { Label("All decks", systemImage: "checkmark") } else { Text("All decks") }
                }
                ForEach(model.decks) { deck in
                    Button { model.deck = deck } label: {
                        let indent = String(repeating: "\u{2003}", count: deck.depth)
                        if model.deck == deck {
                            Label(indent + deck.leafName, systemImage: "checkmark")
                        } else {
                            Text(indent + deck.leafName)
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if let parent = model.deck?.parentPath {
                        Text(parent)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    HStack(spacing: 6) {
                        Text(model.deck?.leafName ?? "All decks")
                            .font(.display(DisplaySize.sectionHeading, relativeTo: .title2))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.text2)
                            .accessibilityHidden(true)
                    }
                }
                .frame(minHeight: Theme.minTarget, alignment: .leading)
            }
            .accessibilityIdentifier("stats-deck-picker")
            .accessibilityLabel("Deck: \(model.deck?.name.replacingOccurrences(of: "::", with: ", ") ?? "All decks")")
            Spacer(minLength: 0)
        }
    }

    private var rangeChips: some View {
        HStack(spacing: 8) {
            ForEach(StatsRange.allCases) { range in
                let selected = model.range == range
                Button(range.rawValue) {
                    withAnimation(.easeInOut(duration: 0.2)) { model.range = range }
                    UIAccessibility.post(notification: .announcement, argument: "Showing \(range.phrase)")
                }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: Theme.minTarget)
                    .background(selected ? Theme.accent : Theme.control, in: Capsule())
                    .foregroundStyle(selected ? Theme.onAccent : Theme.text2)
                    .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer()
        }
    }

    private var hero: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("True retention · last \(model.range.phrase)").inkLabel()
                if let retention = model.retention {
                    Text(retention, format: .percent.precision(.fractionLength(0)))
                        .font(.display(DisplaySize.retention))
                        .foregroundStyle(Theme.accent)
                    Text("from \(model.retentionReviews) reviews")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                } else {
                    Text("–")
                        .font(.display(DisplaySize.retention)).foregroundStyle(Theme.muted)
                    Text("No reviews in this range").font(.subheadline).foregroundStyle(Theme.text2)
                }
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                Label("\(model.streak) day streak", systemImage: "flame")
                let totals = model.totals
                Label("\(totals.reviews) reviews", systemImage: "rectangle.stack")
                Label("\(totals.minutes) min", systemImage: "clock")
                Label("\(totals.daysStudied) of \(model.range.days) days", systemImage: "calendar")
            }
            .font(.footnote)
            .foregroundStyle(Theme.text2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stats-hero")
    }

    private var activityTitle: String {
        switch model.range {
        case .week: "Reviews, last 7 days"
        case .month: "Reviews, last 30 days"
        case .year: "Reviews, last 52 weeks"
        }
    }

    private var activity: some View {
        let counts = model.activity
        return VStack(alignment: .leading, spacing: 12) {
            Text(activityTitle).inkLabel()
            if model.range == .year {
                yearHeatmap(counts)
            } else {
                dailyBars(counts)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activityTitle), \(counts.reduce(0, +)) in total")
        .accessibilityIdentifier("stats-activity")
    }

    private func dailyBars(_ counts: [Int]) -> some View {
        let calendar = Calendar.current
        let last = counts.count - 1
        return Chart(counts.indices, id: \.self) { index in
            let date = calendar.date(byAdding: .day, value: index - last, to: .now) ?? .now
            BarMark(x: .value("Day", date, unit: .day), y: .value("Reviews", counts[index]))
                .foregroundStyle(index == last ? Theme.accent : Theme.raised)
                .cornerRadius(4)
        }
        .chartXAxis {
            if model.range == .week {
                AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) }
            } else {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)) }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 160)
    }

    private func yearHeatmap(_ counts: [Int]) -> some View {
        let peak = max(counts.max() ?? 1, 1)
        let columns = counts.count / 7
        let calendar = Calendar.current
        let cell: CGFloat = 12
        return VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 3) {
                    ForEach(0..<columns, id: \.self) { column in
                        let start = calendar.date(byAdding: .day, value: column * 7 - (counts.count - 1), to: .now) ?? .now
                        let newMonth = column == 0 || calendar.component(.month, from: start) != calendar.component(
                            .month, from: calendar.date(byAdding: .day, value: -7, to: start) ?? start)
                        VStack(spacing: 3) {
                            Text(newMonth ? start.formatted(.dateTime.month(.abbreviated)) : " ")
                                .font(.caption2).foregroundStyle(Theme.muted)
                                .fixedSize()
                                .frame(width: cell, alignment: .leading)
                            ForEach(0..<7, id: \.self) { row in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.heatmap[Self.step(counts[column * 7 + row], peak: peak)])
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
            HStack(spacing: 4) {
                Text("Less").font(.caption2).foregroundStyle(Theme.muted)
                ForEach(0..<5, id: \.self) { RoundedRectangle(cornerRadius: 2).fill(Theme.heatmap[$0]).frame(width: 12, height: 12) }
                Text("More").font(.caption2).foregroundStyle(Theme.muted)
            }
        }
    }

    private static func step(_ value: Int, peak: Int) -> Int {
        value == 0 ? 0 : min(4, 1 + value * 4 / (peak + 1))
    }

    private var forecastTitle: String {
        switch model.range {
        case .week: "Forecast, next 7 days"
        case .month: "Forecast, next 30 days"
        case .year: "Forecast, next 12 months"
        }
    }

    private var forecast: some View {
        let due = model.forecast
        let calendar = Calendar.current
        let unit: Calendar.Component = model.range == .year ? .month : .day
        let step = model.range.forecastBucketDays
        return VStack(alignment: .leading, spacing: 12) {
            Text(forecastTitle).inkLabel()
            Chart(due.indices, id: \.self) { bucket in
                BarMark(
                    x: .value("Day", calendar.date(byAdding: .day, value: bucket * step, to: .now) ?? .now, unit: unit),
                    y: .value("Due", due[bucket])
                )
                .foregroundStyle(bucket == 0 ? Theme.accent : Theme.raised)
                .cornerRadius(6)
            }
            .chartXAxis {
                switch model.range {
                case .week:
                    AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) }
                case .month:
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)) }
                case .year:
                    AxisMarks(values: .stride(by: .month, count: 2)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated)) }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 160)
        }
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(forecastTitle): \(due.reduce(0, +)) cards due")
        .accessibilityIdentifier("stats-forecast")
    }

    private var moreStats: some View {
        Button { showMore = true } label: {
            Label("More stats", systemImage: "chart.line.uptrend.xyaxis")
                .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        }
        .buttonStyle(.bordered)
        .tint(Theme.accent)
        .accessibilityIdentifier("more-stats")
    }
}
