import Foundation

/// A deck as shown on the Decks home, built from the engine's `deck_tree` node.
struct DeckTile: Identifiable, Hashable {
    let id: Int64
    let name: String
    let newCount: Int
    let learningCount: Int
    let reviewCount: Int
    let totalCards: Int
    var collapsed: Bool
    let children: [DeckTile]
    /// The deck's full name with `::` separators, as the engine stores it.
    var fullName = ""

    var dueCount: Int { newCount + learningCount + reviewCount }

    /// Hanzi numeral for "HSK n" decks, otherwise the first character of the name.
    var glyph: String {
        let numerals = ["1": "一", "2": "二", "3": "三", "4": "四"]
        let parts = name.split(separator: " ")
        if parts.count == 2, parts[0].uppercased() == "HSK", let numeral = numerals[String(parts[1])] {
            return numeral
        }
        return name.first.map { String($0).uppercased() } ?? "?"
    }

    /// Share of the deck's cards that are not due today.
    var progress: Double {
        guard totalCards > 0 else { return 0 }
        return max(0, min(1, 1 - Double(dueCount) / Double(totalCards)))
    }

    var accessibilityLabel: String {
        "\(name): \(newCount) new, \(learningCount) learning, \(reviewCount) review"
    }

    static func tiles(from node: Anki_Decks_DeckTreeNode, parent: String = "") -> [DeckTile] {
        node.children.map { child in
            let full = parent.isEmpty ? child.name : "\(parent)::\(child.name)"
            let short = child.name.split(separator: ":").last.map(String.init) ?? child.name
            return DeckTile(
                id: child.deckID, name: short, newCount: Int(child.newCount), learningCount: Int(child.learnCount),
                reviewCount: Int(child.reviewCount), totalCards: Int(child.totalIncludingChildren),
                collapsed: child.collapsed, children: tiles(from: child, parent: full), fullName: full)
        }
    }
}
