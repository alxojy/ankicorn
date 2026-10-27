import Foundation

extension Backend {
    /// `add_deck`: adds a normal deck named `name` ("Parent::Child" creates the parents). Returns its id.
    @discardableResult
    func addDeck(name: String) throws -> Int64 {
        var deck = Anki_Decks_Deck()
        deck.name = name
        deck.normal = Anki_Decks_Deck.Normal()
        let result: Anki_Collection_OpChangesWithId = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.addDeck, deck)
        return result.id
    }

    /// `deck_tree`: the synthetic root node whose `children` are the top-level decks. A non-zero `now`
    /// includes due counts for that timestamp.
    func deckTree(now: Int64 = 0) throws -> Anki_Decks_DeckTreeNode {
        var request = Anki_Decks_DeckTreeRequest()
        request.now = now
        return try call(service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.deckTree, request)
    }
}
