import SwiftUI

/// Coloured new / learning / review counts; zeros use the `zero` token.
struct CountsLine: View {
    let new: Int
    let learning: Int
    let review: Int

    var body: some View {
        HStack(spacing: 12) {
            count(new, Theme.new)
            count(learning, Theme.learning)
            count(review, Theme.accent)
        }
        .font(.display(DisplaySize.tileCount, relativeTo: .subheadline))
        .monospacedDigit()
    }

    private func count(_ value: Int, _ color: Color) -> some View {
        Text("\(value)").foregroundStyle(value == 0 ? Theme.zero : color)
    }
}

struct DeckTileView: View {
    let deck: DeckTile
    /// Position in the grid; the glyph colour cycles new, learning, synced, again.
    var index = 0

    private var glyphColor: Color { [Theme.new, Theme.learning, Theme.synced, Theme.again][index % 4] }

    private var glyphFont: Font {
        let isLatin = deck.glyph.unicodeScalars.allSatisfy { $0.isASCII }
        return isLatin
            ? .system(.title, design: .default, weight: .bold)
            : .custom("PingFangSC-Semibold", size: DisplaySize.tileGlyph, relativeTo: .title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(deck.glyph)
                .font(glyphFont)
                .foregroundStyle(glyphColor)
                .minimumScaleFactor(0.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text("\(deck.totalCards) cards")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            CountsLine(new: deck.newCount, learning: deck.learningCount, review: deck.reviewCount)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.raised)
                    Capsule().fill(Theme.accent).frame(width: proxy.size.width * deck.progress)
                }
            }
            .frame(height: Theme.Radius.bar)
            .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile).strokeBorder(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(deck.accessibilityLabel)
        .accessibilityIdentifier("deck-tile")
    }
}

/// 2-column grid of deck tiles; each links to the deck's overview.
struct DeckGrid: View {
    let decks: [DeckTile]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(Array(decks.enumerated()), id: \.element.id) { index, deck in
                NavigationLink(value: deck) { DeckTileView(deck: deck, index: index) }
                    .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    DeckGrid(decks: [
        DeckTile(id: 1, name: "HSK 1", newCount: 12, learningCount: 0, reviewCount: 30, totalCards: 150, collapsed: false, children: []),
        DeckTile(id: 2, name: "Travel", newCount: 0, learningCount: 3, reviewCount: 0, totalCards: 40, collapsed: false, children: []),
    ])
    .padding()
    .background(Theme.bg)
}
