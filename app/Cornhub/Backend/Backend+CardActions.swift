import Foundation

extension Backend {
    /// `set_flag`: flag 0 clears, 1...7 are the colours.
    func setFlag(cardID: Int64, flag: UInt32) throws {
        var request = Anki_Cards_SetFlagRequest()
        request.cardIds = [cardID]
        request.flag = flag
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Cards.service, method: ServiceIndex.Cards.setFlag, request)
    }

    /// `bury_or_suspend_cards`.
    func buryOrSuspend(cardID: Int64, mode: Anki_Scheduler_BuryOrSuspendCardsRequest.Mode) throws {
        var request = Anki_Scheduler_BuryOrSuspendCardsRequest()
        request.cardIds = [cardID]
        request.mode = mode
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.buryOrSuspendCards, request)
    }

    /// `get_note`.
    func getNote(id: Int64) throws -> Anki_Notes_Note {
        var request = Anki_Notes_NoteId()
        request.nid = id
        return try call(service: ServiceIndex.Notes.service, method: ServiceIndex.Notes.getNote, request)
    }

    /// `update_notes`.
    func updateNote(_ note: Anki_Notes_Note) throws {
        var request = Anki_Notes_UpdateNotesRequest()
        request.notes = [note]
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Notes.service, method: ServiceIndex.Notes.updateNotes, request)
    }

    /// `add_note_tags` / `remove_note_tags` for one tag on one note.
    func setNoteTag(noteID: Int64, tag: String, present: Bool) throws {
        var request = Anki_Tags_NoteIdsAndTagsRequest()
        request.noteIds = [noteID]
        request.tags = tag
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Tags.service,
            method: present ? ServiceIndex.Tags.addNoteTags : ServiceIndex.Tags.removeNoteTags, request)
    }

    /// `custom_study_defaults`: limits and tags offered for a deck.
    func customStudyDefaults(deckID: Int64) throws -> Anki_Scheduler_CustomStudyDefaultsResponse {
        var request = Anki_Scheduler_CustomStudyDefaultsRequest()
        request.deckID = deckID
        return try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.customStudyDefaults, request)
    }

    /// `custom_study`.
    func customStudy(_ request: Anki_Scheduler_CustomStudyRequest) throws {
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.customStudy, request)
    }

    /// `unbury_deck`.
    func unburyDeck(id: Int64) throws {
        var request = Anki_Scheduler_UnburyDeckRequest()
        request.deckID = id
        request.mode = .all
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.unburyDeck, request)
    }

    /// Cards in the deck (and its subdecks) that are buried, from the engine's `is:buried` search.
    func buriedCardIDs(deckName: String) throws -> [Int64] {
        let escaped = deckName.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return try browserSearch("\"deck:\(escaped)\" is:buried", notes: false)
    }
}
