import Foundation

/// One flattened row of the engine's deck tree.
struct DeckRow: Identifiable, Equatable {
    let id: Int64
    /// The last component of the deck name, as the engine returns it.
    let name: String
    /// The full "Parent::Child" name.
    let fullName: String
    let level: Int

    /// Flattens the tree in display order, skipping the engine's synthetic root.
    static func rows(from root: Anki_Decks_DeckTreeNode) -> [DeckRow] {
        var rows: [DeckRow] = []
        func walk(_ node: Anki_Decks_DeckTreeNode, parent: String) {
            for child in node.children {
                let full = parent.isEmpty ? child.name : "\(parent)::\(child.name)"
                rows.append(DeckRow(id: child.deckID, name: child.name, fullName: full, level: Int(child.level)))
                walk(child, parent: full)
            }
        }
        walk(root, parent: "")
        return rows
    }
}
