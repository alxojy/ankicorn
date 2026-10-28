import SwiftUI

/// Rounded Ink card used by every section of the deck screen.
private struct InkCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile).strokeBorder(Theme.hairline, lineWidth: 1))
    }
}

extension View {
    func inkCard() -> some View { modifier(InkCard()) }
}

/// A horizontal bar split into coloured segments; widths are fractions of the total.
struct SegmentBar: View {
    let segments: [(value: Int, color: Color)]
    @ScaledMetric(relativeTo: .body) private var height = 8.0

    var body: some View {
        GeometryReader { proxy in
            let total = max(segments.reduce(0) { $0 + $1.value }, 1)
            HStack(spacing: 2) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    if segment.value > 0 {
                        RoundedRectangle(cornerRadius: Theme.Radius.bar)
                            .fill(segment.color)
                            .frame(width: max(proxy.size.width * CGFloat(segment.value) / CGFloat(total) - 2, 2))
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: height)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.Radius.bar))
        .accessibilityHidden(true)
    }
}

/// Level icon: the deck's glyph on a raised rounded square.
struct LevelIcon: View {
    let deck: DeckTile
    var index = 0
    @ScaledMetric(relativeTo: .body) private var side = 36.0

    private var color: Color { [Theme.new, Theme.learning, Theme.synced, Theme.again][index % 4] }

    var body: some View {
        Text(deck.glyph)
            .font(.display(DisplaySize.tileCount, relativeTo: .headline))
            .foregroundStyle(color)
            .minimumScaleFactor(0.5)
            .frame(width: side, height: side)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.Radius.bar * 2))
            .accessibilityHidden(true)
    }
}

/// Total cards, the Mature / Young / unseen bar, its legend and when the deck was last studied.
struct CollectionCard: View {
    let counts: DeckCardCounts
    let lastStudied: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(counts.total.formatted()) \(counts.total == 1 ? "card" : "cards")")
                    .font(.headline).foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                Text(counts.unseen == 0 ? "All seen" : "\(counts.unseen.formatted()) new")
                    .font(.subheadline).foregroundStyle(counts.unseen == 0 ? Theme.accent : Theme.new)
                    .accessibilityIdentifier("collection-seen")
            }
            SegmentBar(segments: [(counts.mature, Theme.accent), (counts.young, Theme.learning), (counts.unseen, Theme.zero)])
            HStack(spacing: 16) {
                legend("Mature", counts.mature, Theme.accent)
                legend("Young", counts.young, Theme.learning)
                legend("New", counts.unseen, Theme.zero)
            }
            Text(lastStudied).font(.footnote).foregroundStyle(Theme.muted)
                .accessibilityIdentifier("last-studied")
        }
        .inkCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(counts.total) cards: \(counts.mature) mature, \(counts.young) young, \(counts.unseen) new. \(lastStudied)")
        .accessibilityIdentifier("collection-card")
    }

    private func legend(_ title: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(title) \(value.formatted())").font(.caption).foregroundStyle(Theme.text2)
        }
    }
}

/// One of the three Today tiles. A capped tile is a button that explains the limit.
struct TodayTile: View {
    let title: String
    let value: Int
    let color: Color
    var cappedLine: String?
    let identifier: String
    var action: () -> Void = {}

    var body: some View {
        if cappedLine != nil {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityHint("Explains the daily limit")
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(Theme.text2)
            Text("\(value)")
                .font(.display(DisplaySize.heroCaption, relativeTo: .title))
                .monospacedDigit()
                .foregroundStyle(value == 0 ? Theme.zero : color)
            Text(cappedLine ?? " ").font(.caption2).foregroundStyle(Theme.muted)
                .lineLimit(2).multilineTextAlignment(.center).opacity(cappedLine == nil ? 0 : 1)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        .padding(.vertical, 10)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.Radius.photo))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)" + (cappedLine.map { ", \($0)" } ?? ""))
        .accessibilityIdentifier(identifier)
    }
}

/// One row of the Levels list: icon, name, seen bar and the three coloured counts.
struct LevelRow: View {
    let deck: DeckTile
    let counts: DeckCardCounts?
    var index = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .subheadline) static var column = 36.0

    private var seenText: String {
        guard let counts else { return "" }
        return "\(counts.seen.formatted()) / \(counts.total.formatted()) seen"
    }

    var body: some View {
        HStack(spacing: 12) {
            LevelIcon(deck: deck, index: index)
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text).lineLimit(2)
                if let counts {
                    SegmentBar(segments: [(counts.seen, Theme.accent)].filter { $0.0 > 0 } + [(counts.unseen, Theme.zero)])
                    Text(seenText).font(.caption2).foregroundStyle(Theme.muted)
                }
                if typeSize.isAccessibilitySize { LevelCounts(deck: deck) }
            }
            Spacer(minLength: 4)
            if !typeSize.isAccessibilitySize { LevelCounts(deck: deck) }
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: Theme.minTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(deck.name): \(seenText.isEmpty ? "" : seenText + ", ")\(deck.newCount) new, \(deck.learningCount) learning, \(deck.reviewCount) review"
        )
        .accessibilityIdentifier("level-row")
    }
}

private struct LevelCounts: View {
    let deck: DeckTile

    var body: some View {
        HStack(spacing: 0) {
            cell(deck.newCount, Theme.new)
            cell(deck.learningCount, Theme.learning)
            cell(deck.reviewCount, Theme.accent)
        }
    }

    private func cell(_ value: Int, _ color: Color) -> some View {
        Text("\(value)")
            .font(.display(DisplaySize.tileCount, relativeTo: .subheadline)).monospacedDigit()
            .foregroundStyle(value == 0 ? Theme.zero : color)
            .frame(minWidth: LevelRow.column, alignment: .trailing)
    }
}

/// "LEVELS" header with the New / Learn / Due column labels.
struct LevelsHeader: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(spacing: 0) {
            Text("Levels").inkLabel()
            Spacer(minLength: 8)
            if !typeSize.isAccessibilitySize {
                HStack(spacing: 0) {
                    column("New")
                    column("Learn")
                    column("Due")
                }
                .padding(.trailing, 24)
            }
        }
        .padding(.horizontal, 12)
        .accessibilityHidden(true)
    }

    private func column(_ title: String) -> some View {
        Text(title).font(.caption2).foregroundStyle(Theme.muted)
            .lineLimit(1).minimumScaleFactor(0.7)
            .frame(minWidth: LevelRow.column, alignment: .trailing)
    }
}

/// The next 7 days of due cards as bars, tomorrow highlighted, with tomorrow and 7-day totals.
struct ComingUpCard: View {
    let forecast: [Int]
    @ScaledMetric(relativeTo: .body) private var barHeight = 56.0

    private var tomorrow: Int { forecast.first ?? 0 }
    private var week: Int { forecast.reduce(0, +) }

    private func initial(_ offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset + 1, to: Date()) ?? Date()
        return String(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coming up").inkLabel()
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.text2)
            }
            HStack(alignment: .bottom, spacing: 6) {
                let peak = max(forecast.max() ?? 0, 1)
                ForEach(Array(forecast.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: Theme.Radius.bar)
                            .fill(index == 0 ? Theme.accent : Theme.raisedHigh)
                            .frame(height: max(barHeight * CGFloat(value) / CGFloat(peak), 3))
                        Text(initial(index)).font(.caption2).foregroundStyle(index == 0 ? Theme.text : Theme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: barHeight + 20, alignment: .bottom)
            HStack {
                Text("Tomorrow \(tomorrow)").foregroundStyle(Theme.text)
                Spacer()
                Text("Next 7 days \(week)").foregroundStyle(Theme.text2)
            }
            .font(.subheadline).monospacedDigit()
        }
        .inkCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coming up: tomorrow \(tomorrow) cards, next 7 days \(week) cards")
        .accessibilityHint("Opens Stats for this deck")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("coming-up")
    }
}

/// One tappable row of the Rows card (Browse cards, Custom study, Daily limits & options).
struct DeckActionRow: View {
    let title: String
    let symbol: String
    var detail: String?
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 28)
                Text(title).font(.subheadline).foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                if let detail { Text(detail).font(.subheadline).foregroundStyle(Theme.muted) }
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.text2)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: Theme.minTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detail.map { "\(title), \($0)" } ?? title)
        .accessibilityIdentifier(identifier)
    }
}

/// Explains a held-back daily limit and links to Daily limits & options.
struct LimitSheet: View {
    enum Kind: String, Identifiable {
        case new, review
        var id: String { rawValue }
    }

    let kind: Kind
    let available: Int
    let shown: Int
    let openOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(kind == .new ? "New cards limit" : "Review limit")
                .font(.display(DisplaySize.sectionHeading, relativeTo: .title2)).foregroundStyle(Theme.text)
            Text(
                kind == .new
                    ? "\(available) new cards are waiting, but today's new card limit shows \(shown)."
                    : "\(available) reviews are due, but today's review limit shows \(shown).")
                .font(.body).foregroundStyle(Theme.text2)
            Text("The rest come back on later days. You can raise the limit in Daily limits & options.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            Button(action: openOptions) {
                Text("Daily limits & options").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent).foregroundStyle(Theme.onAccent)
            .accessibilityIdentifier("limit-sheet-options")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        .accessibilityIdentifier("limit-sheet")
    }
}
