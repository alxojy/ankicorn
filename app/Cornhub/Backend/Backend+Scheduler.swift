import Foundation

extension Backend {
    /// `counts_for_deck_today`: the new and review counts for a deck, limits applied.
    func countsForDeckToday(deckID: Int64) throws -> Anki_Scheduler_CountsForDeckTodayResponse {
        var request = Anki_Decks_DeckId()
        request.did = deckID
        return try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.countsForDeckToday, request)
    }

    /// `studied_today`: the engine's own sentence, e.g. "Studied 12 cards in 3 minutes today."
    func studiedToday() throws -> String {
        let result: Anki_Generic_String = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.studiedToday,
            Anki_Generic_Empty())
        return result.val
    }
}
