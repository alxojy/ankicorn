import Foundation

extension Backend {
    /// `get_notetype_names`: id and name of every note type.
    func notetypeNames() throws -> [Anki_Notetypes_NotetypeNameId] {
        let names: Anki_Notetypes_NotetypeNames = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.getNotetypeNames,
            Anki_Generic_Empty())
        return names.entries
    }

    /// `get_stock_notetype_legacy`: the stock note type of `kind` as legacy JSON.
    func stockNotetypeJSON(kind: Anki_Notetypes_StockNotetype.Kind) throws -> Data {
        var request = Anki_Notetypes_StockNotetype()
        request.kind = kind
        let json: Anki_Generic_Json = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.getStockNotetypeLegacy, request)
        return json.json
    }

    /// `add_notetype_legacy`: adds a note type from its legacy JSON. Returns its id.
    @discardableResult
    func addNotetype(json: Data) throws -> Int64 {
        var request = Anki_Generic_Json()
        request.json = json
        let result: Anki_Collection_OpChangesWithId = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.addNotetypeLegacy, request)
        return result.id
    }

    /// The id of the note type named `name`, adding the stock one of `kind` first when it is missing.
    func ensureStockNotetype(named name: String, kind: Anki_Notetypes_StockNotetype.Kind) throws -> Int64 {
        if let existing = try notetypeNames().first(where: { $0.name == name }) { return existing.id }
        return try addNotetype(json: try stockNotetypeJSON(kind: kind))
    }

    /// `add_note`: adds a note with the given fields (in field order) to a deck.
    @discardableResult
    func addNote(notetypeID: Int64, deckID: Int64, fields: [String], tags: [String] = []) throws -> Int64 {
        var note = Anki_Notes_Note()
        note.notetypeID = notetypeID
        note.fields = fields
        note.tags = tags
        var request = Anki_Notes_AddNoteRequest()
        request.note = note
        request.deckID = deckID
        let response: Anki_Notes_AddNoteResponse = try call(
            service: ServiceIndex.Notes.service, method: ServiceIndex.Notes.addNote, request)
        return response.noteID
    }
}
