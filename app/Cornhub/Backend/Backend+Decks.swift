import Foundation

extension Backend {
    /// `new_deck`: the engine's template for a normal deck (carries a real `config_id`).
    func newDeck() throws -> Anki_Decks_Deck {
        try call(service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.newDeck, Anki_Generic_Empty())
    }

    /// `get_deck_config`: the options preset with the given id; throws when it does not exist.
    func getDeckConfig(id: Int64) throws -> Anki_DeckConfig_DeckConfig {
        var request = Anki_DeckConfig_DeckConfigId()
        request.dcid = id
        return try call(
            service: ServiceIndex.DeckConfig.service, method: ServiceIndex.DeckConfig.getDeckConfig, request)
    }

    /// `add_deck`: adds a normal deck named `name` ("Parent::Child" creates the parents). Returns its id.
    @discardableResult
    func addDeck(name: String) throws -> Int64 {
        var deck = try newDeck()
        deck.name = name
        let result: Anki_Collection_OpChangesWithId = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.addDeck, deck)
        return result.id
    }

    /// `get_deck`: the deck with this id; throws when it does not exist.
    func getDeck(id: Int64) throws -> Anki_Decks_Deck {
        var request = Anki_Decks_DeckId()
        request.did = id
        return try call(service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.getDeck, request)
    }

    /// `deck_tree`: the synthetic root node whose `children` are the top-level decks. A non-zero `now`
    /// includes due counts for that timestamp.
    func deckTree(now: Int64 = 0) throws -> Anki_Decks_DeckTreeNode {
        var request = Anki_Decks_DeckTreeRequest()
        request.now = now
        return try call(service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.deckTree, request)
    }
}

extension Backend {
    /// `set_deck_collapsed`: stores the collapsed state of a deck in the given scope.
    func setDeckCollapsed(deckID: Int64, collapsed: Bool, browser: Bool = false) throws {
        var request = Anki_Decks_SetDeckCollapsedRequest()
        request.deckID = deckID
        request.collapsed = collapsed
        request.scope = browser ? .browser : .reviewer
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.setDeckCollapsed, request)
    }
}

extension Backend {
    /// `set_current_deck`: the deck (and subdecks) the scheduler queues cards from.
    func setCurrentDeck(_ deckID: Int64) throws {
        var request = Anki_Decks_DeckId()
        request.did = deckID
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.setCurrentDeck, request)
    }
}

extension Backend {
    /// `remove_decks`: deletes the decks, their subdecks and their cards (undoable). Returns the removed card count.
    @discardableResult
    func removeDecks(ids: [Int64]) throws -> Int {
        var request = Anki_Decks_DeckIds()
        request.dids = ids
        let result: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.removeDecks, request)
        return Int(result.count)
    }

    /// `rename_deck`: `name` is the full name; "Parent::Child" makes a subdeck. The engine validates it.
    func renameDeck(id: Int64, name: String) throws {
        var request = Anki_Decks_RenameDeckRequest()
        request.deckID = id
        request.newName = name
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.renameDeck, request)
    }
}
