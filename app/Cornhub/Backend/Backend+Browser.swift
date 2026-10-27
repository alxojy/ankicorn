import Foundation

extension Backend {
    /// `all_browser_columns`: the columns the engine can show, with their labels.
    func allBrowserColumns() throws -> [Anki_Search_BrowserColumns.Column] {
        let columns: Anki_Search_BrowserColumns = try call(
            service: ServiceIndex.Search.service, method: ServiceIndex.Search.allBrowserColumns,
            Anki_Generic_Empty())
        return columns.columns
    }

    /// `set_active_browser_columns`: which columns `browser_row_for_id` fills in, in order.
    func setActiveBrowserColumns(_ keys: [String]) throws {
        var request = Anki_Generic_StringList()
        request.vals = keys
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Search.service, method: ServiceIndex.Search.setActiveBrowserColumns, request)
    }

    /// `set_config_bool` for the browser's cards/notes mode, which decides what ids mean.
    func setBrowserNotesMode(_ notesMode: Bool) throws {
        var request = Anki_Config_SetConfigBoolRequest()
        request.key = .browserTableShowNotesMode
        request.value = notesMode
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Config.service, method: ServiceIndex.Config.setConfigBool, request)
    }

    /// `search_cards` or `search_notes`, sorted by a built-in column key (empty keeps the engine default).
    func browserSearch(_ search: String, notes: Bool, sortColumn: String = "", reverse: Bool = false) throws -> [Int64] {
        var request = Anki_Search_SearchRequest()
        request.search = search
        if sortColumn.isEmpty {
            request.order.none = Anki_Generic_Empty()
        } else {
            var builtin = Anki_Search_SortOrder.Builtin()
            builtin.column = sortColumn
            builtin.reverse = reverse
            request.order.builtin = builtin
        }
        let response: Anki_Search_SearchResponse = try call(
            service: ServiceIndex.Search.service,
            method: notes ? ServiceIndex.Search.searchNotes : ServiceIndex.Search.searchCards, request)
        return response.ids
    }

    /// `browser_row_for_id`: the cells for a card or note id, in the active column order.
    func browserRow(id: Int64) throws -> Anki_Search_BrowserRow {
        var request = Anki_Generic_Int64()
        request.val = id
        return try call(service: ServiceIndex.Search.service, method: ServiceIndex.Search.browserRowForId, request)
    }

    /// `get_card`.
    func getCard(id: Int64) throws -> Anki_Cards_Card {
        var request = Anki_Cards_CardId()
        request.cid = id
        return try call(service: ServiceIndex.Cards.service, method: ServiceIndex.Cards.getCard, request)
    }

    /// The card ids of the given notes (a `nid:` search), so note-mode rows can use card actions.
    func cardIDs(ofNotes noteIDs: [Int64]) throws -> [Int64] {
        guard !noteIDs.isEmpty else { return [] }
        let search = "nid:" + noteIDs.map(String.init).joined(separator: ",")
        return try browserSearch(search, notes: false)
    }

    /// `set_deck`.
    func setDeck(cardIDs: [Int64], deckID: Int64) throws {
        var request = Anki_Cards_SetDeckRequest()
        request.cardIds = cardIDs
        request.deckID = deckID
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Cards.service, method: ServiceIndex.Cards.setDeck, request)
    }

    /// `add_note_tags` / `remove_note_tags` for several notes; `tags` is space separated.
    func changeTags(noteIDs: [Int64], tags: String, add: Bool) throws {
        var request = Anki_Tags_NoteIdsAndTagsRequest()
        request.noteIds = noteIDs
        request.tags = tags
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Tags.service,
            method: add ? ServiceIndex.Tags.addNoteTags : ServiceIndex.Tags.removeNoteTags, request)
    }

    /// `sort_cards`: repositions new cards.
    func reposition(cardIDs: [Int64], start: UInt32, step: UInt32, randomize: Bool, shift: Bool) throws {
        var request = Anki_Scheduler_SortCardsRequest()
        request.cardIds = cardIDs
        request.startingFrom = start
        request.stepSize = step
        request.randomize = randomize
        request.shiftExisting = shift
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.sortCards, request)
    }

    /// `set_due_date`: `days` uses Anki's syntax, e.g. "0", "3" or "3-7!".
    func setDueDate(cardIDs: [Int64], days: String) throws {
        var request = Anki_Scheduler_SetDueDateRequest()
        request.cardIds = cardIDs
        request.days = days
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.setDueDate, request)
    }

    /// `schedule_cards_as_new`: forget the cards' progress.
    func forget(cardIDs: [Int64]) throws {
        var request = Anki_Scheduler_ScheduleCardsAsNewRequest()
        request.cardIds = cardIDs
        request.log = true
        request.restorePosition = true
        request.resetCounts = false
        request.context = .browser
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.scheduleCardsAsNew, request)
    }

    /// `bury_or_suspend_cards` (suspend) or `restore_buried_and_suspended_cards` (unsuspend) for several cards.
    func suspend(cardIDs: [Int64], suspend: Bool) throws {
        if suspend {
            var request = Anki_Scheduler_BuryOrSuspendCardsRequest()
            request.cardIds = cardIDs
            request.mode = .suspend
            let _: Anki_Collection_OpChangesWithCount = try call(
                service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.buryOrSuspendCards, request)
        } else {
            var request = Anki_Cards_CardIds()
            request.cids = cardIDs
            let _: Anki_Collection_OpChanges = try call(
                service: ServiceIndex.Scheduler.service,
                method: ServiceIndex.Scheduler.restoreBuriedAndSuspendedCards, request)
        }
    }

    /// `remove_notes`.
    func deleteNotes(noteIDs: [Int64]) throws {
        var request = Anki_Notes_RemoveNotesRequest()
        request.noteIds = noteIDs
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Notes.service, method: ServiceIndex.Notes.removeNotes, request)
    }
}
