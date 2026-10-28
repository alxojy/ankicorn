import Charts
import SwiftUI

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
                        hero
                        heatmap
                        forecast
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
        .task { await model.load() }
        .sheet(isPresented: $showMore) { AnkiWebSheet(page: .graphs, backend: backend) }
    }

    private var deckPicker: some View {
        HStack {
            Menu {
                Button("All decks") { model.deck = nil }
                ForEach(model.decks) { deck in Button(deck.name) { model.deck = deck } }
            } label: {
                Label(model.deck?.name ?? "All decks", systemImage: "chevron.down")
                    .labelStyle(.titleAndIcon)
                    .font(.inkAnswer)
                    .foregroundStyle(Theme.text)
                    .frame(minHeight: Theme.minTarget)
            }
            .accessibilityLabel("Deck: \(model.deck?.name ?? "All decks")")
            Spacer()
        }
    }

    private var rangeChips: some View {
        HStack(spacing: 8) {
            ForEach(StatsRange.allCases) { range in
                let selected = model.range == range
                Button(range.rawValue) { model.range = range }
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
                Text("True retention").inkLabel()
                if let retention = model.retention {
                    Text(retention, format: .percent.precision(.fractionLength(0)))
                        .font(.display(DisplaySize.retention))
                        .foregroundStyle(Theme.accent)
                    Text(retention >= 0.9 ? "Above your 90% target" : "Below your 90% target")
                        .font(.subheadline).foregroundStyle(Theme.text2)
                } else {
                    Text("–")
                        .font(.display(DisplaySize.retention)).foregroundStyle(Theme.muted)
                    Text("No answers in this range").font(.subheadline).foregroundStyle(Theme.text2)
                }
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                Label("\(model.streak) day streak", systemImage: "flame")
                Label("\(model.todayCount) cards today", systemImage: "rectangle.stack")
                Label("\(model.todayMinutes) min today", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(Theme.text2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .combine)
    }

    private var heatmap: some View {
        let counts = model.heatmap
        let peak = max(counts.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Last 16 weeks").inkLabel()
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<7, id: \.self) { row in
                    GridRow {
                        ForEach(0..<16, id: \.self) { column in
                            let value = counts[column * 7 + row]
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.heatmap[Self.step(value, peak: peak)])
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            HStack(spacing: 4) {
                Text("Less").font(.caption2).foregroundStyle(Theme.muted)
                ForEach(0..<5, id: \.self) { RoundedRectangle(cornerRadius: 2).fill(Theme.heatmap[$0]).frame(width: 12, height: 12) }
                Text("More").font(.caption2).foregroundStyle(Theme.muted)
            }
        }
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reviews over the last 16 weeks, \(counts.reduce(0, +)) in total")
    }

    private static func step(_ value: Int, peak: Int) -> Int {
        value == 0 ? 0 : min(4, 1 + value * 4 / (peak + 1))
    }

    private var forecast: some View {
        let due = model.forecast
        let calendar = Calendar.current
        return VStack(alignment: .leading, spacing: 12) {
            Text("Forecast, next 7 days").inkLabel()
            Chart(0..<7, id: \.self) { day in
                BarMark(
                    x: .value("Day", calendar.date(byAdding: .day, value: day, to: .now) ?? .now, unit: .day),
                    y: .value("Due", due[day])
                )
                .foregroundStyle(day == 0 ? Theme.accent : Theme.raised)
                .cornerRadius(6)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            .chartYAxis(.hidden)
            .frame(height: 160)
        }
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Forecast: \(due.map(String.init).joined(separator: ", ")) cards due over the next 7 days")
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
