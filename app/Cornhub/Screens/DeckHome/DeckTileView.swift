import SwiftUI

/// Coloured new / learning / review counts; zeros use the `zero` token.
struct CountsLine: View {
    let new: Int
    let learning: Int
    let review: Int

    var body: some View {
        HStack(spacing: 10) {
            count(new, Theme.new)
            count(learning, Theme.learning)
            count(review, Theme.accent)
        }
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
    }

    private func count(_ value: Int, _ color: Color) -> some View {
        Text("\(value)").foregroundStyle(value == 0 ? Theme.zero : color)
    }
}

struct DeckTileView: View {
    let deck: DeckTile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(deck.glyph)
                .font(.display(DisplaySize.hanziField, relativeTo: .largeTitle))
                .foregroundStyle(Theme.accent)
                .minimumScaleFactor(0.5)
            Text(deck.name)
                .font(.headline)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Text("\(deck.totalCards) cards")
                .font(.caption)
                .foregroundStyle(Theme.muted)
            CountsLine(new: deck.newCount, learning: deck.learningCount, review: deck.reviewCount)
            ProgressView(value: deck.progress)
                .tint(Theme.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: Theme.minTarget, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
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
            ForEach(decks) { deck in
                NavigationLink(value: deck) { DeckTileView(deck: deck) }
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
