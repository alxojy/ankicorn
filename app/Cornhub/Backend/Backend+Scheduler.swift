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

extension Backend {
    /// `get_queued_cards`: the next cards to study, with the counts left in today's queues.
    func getQueuedCards(fetchLimit: UInt32 = 1) throws -> Anki_Scheduler_QueuedCards {
        var request = Anki_Scheduler_GetQueuedCardsRequest()
        request.fetchLimit = fetchLimit
        return try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.getQueuedCards, request)
    }

    /// `answer_card`: answers a queued card with one of its four proposed next states.
    func answerCard(
        _ queued: Anki_Scheduler_QueuedCards.QueuedCard, rating: Anki_Scheduler_CardAnswer.Rating,
        millisecondsTaken: UInt32
    ) throws {
        var answer = Anki_Scheduler_CardAnswer()
        answer.cardID = queued.card.id
        answer.currentState = queued.states.current
        switch rating {
        case .again: answer.newState = queued.states.again
        case .hard: answer.newState = queued.states.hard
        case .good: answer.newState = queued.states.good
        case .easy: answer.newState = queued.states.easy
        case .UNRECOGNIZED: answer.newState = queued.states.good
        }
        answer.rating = rating
        answer.answeredAtMillis = Int64(Date().timeIntervalSince1970 * 1000)
        answer.millisecondsTaken = millisecondsTaken
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.answerCard, answer)
    }

    /// `describe_next_states`: the interval labels for Again, Hard, Good and Easy ("1m", "2d", ...).
    func describeNextStates(_ states: Anki_Scheduler_SchedulingStates) throws -> [String] {
        let result: Anki_Generic_StringList = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.describeNextStates, states)
        return result.vals
    }

    /// `congrats_info`: why the queue is empty and what is still waiting.
    func congratsInfo() throws -> Anki_Scheduler_CongratsInfoResponse {
        try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.congratsInfo,
            Anki_Generic_Empty())
    }
}
