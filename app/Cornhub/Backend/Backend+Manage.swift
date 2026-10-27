import Foundation

extension Backend {
    // MARK: Filtered decks

    /// `get_or_create_filtered_deck`: the existing filtered deck `deckID`, or defaults when it is 0.
    func filteredDeckForUpdate(deckID: Int64) throws -> Anki_Decks_FilteredDeckForUpdate {
        var request = Anki_Decks_DeckId()
        request.did = deckID
        return try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.getOrCreateFilteredDeck, request)
    }

    /// `add_or_update_filtered_deck`: saves and (re)builds the deck. Returns its id.
    @discardableResult
    func saveFilteredDeck(_ deck: Anki_Decks_FilteredDeckForUpdate) throws -> Int64 {
        let result: Anki_Collection_OpChangesWithId = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.addOrUpdateFilteredDeck, deck)
        return result.id
    }

    /// `rebuild_filtered_deck`.
    func rebuildFilteredDeck(deckID: Int64) throws {
        var request = Anki_Decks_DeckId()
        request.did = deckID
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.rebuildFilteredDeck, request)
    }

    /// `empty_filtered_deck`.
    func emptyFilteredDeck(deckID: Int64) throws {
        var request = Anki_Decks_DeckId()
        request.did = deckID
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Scheduler.service, method: ServiceIndex.Scheduler.emptyFilteredDeck, request)
    }

    // MARK: Tags

    /// `rename_tags`: renames a tag and its children.
    func renameTag(from old: String, to new: String) throws {
        var request = Anki_Tags_RenameTagsRequest()
        request.currentPrefix = old
        request.newPrefix = new
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Tags.service, method: ServiceIndex.Tags.renameTags, request)
    }

    /// `reparent_tags`: moves tags under `newParent` (empty for the top level).
    func reparentTags(_ tags: [String], under newParent: String) throws {
        var request = Anki_Tags_ReparentTagsRequest()
        request.tags = tags
        request.newParent = newParent
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Tags.service, method: ServiceIndex.Tags.reparentTags, request)
    }

    /// `remove_tags`: removes a space-separated list of tags from every note.
    func removeTags(_ tags: String) throws {
        var request = Anki_Generic_String()
        request.val = tags
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Tags.service, method: ServiceIndex.Tags.removeTags, request)
    }

    /// `clear_unused_tags`: returns how many tags were removed.
    @discardableResult
    func clearUnusedTags() throws -> Int {
        let result: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Tags.service, method: ServiceIndex.Tags.clearUnusedTags, Anki_Generic_Empty())
        return Int(result.count)
    }

    // MARK: Note types

    /// `get_notetype_names_and_counts`.
    func notetypeUseCounts() throws -> [Anki_Notetypes_NotetypeNameIdUseCount] {
        let counts: Anki_Notetypes_NotetypeUseCounts = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.getNotetypeNamesAndCounts,
            Anki_Generic_Empty())
        return counts.entries
    }

    /// `get_notetype`.
    func getNotetype(id: Int64) throws -> Anki_Notetypes_Notetype {
        var request = Anki_Notetypes_NotetypeId()
        request.ntid = id
        return try call(service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.getNotetype, request)
    }

    /// `update_notetype`: saves fields, templates and styling; the engine reconciles notes and cards.
    func updateNotetype(_ notetype: Anki_Notetypes_Notetype) throws {
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.updateNotetype, notetype)
    }

    /// `remove_notetype`.
    func removeNotetype(id: Int64) throws {
        var request = Anki_Notetypes_NotetypeId()
        request.ntid = id
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.removeNotetype, request)
    }

    // MARK: Find and replace

    /// `find_and_replace`: replaces in the given notes (empty `field` means every field). Returns notes changed.
    @discardableResult
    func findAndReplace(
        noteIDs: [Int64], search: String, replacement: String, regex: Bool, matchCase: Bool, field: String
    ) throws -> Int {
        var request = Anki_Search_FindAndReplaceRequest()
        request.nids = noteIDs
        request.search = search
        request.replacement = replacement
        request.regex = regex
        request.matchCase = matchCase
        request.fieldName = field
        let result: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Search.service, method: ServiceIndex.Search.findAndReplace, request)
        return Int(result.count)
    }

    /// Groups the notes of a note type that the engine reports as duplicates of each other: for every note
    /// not yet grouped, `dupe:<notetypeId>,<first field>` (the engine's own comparison) lists its twins.
    func findDuplicates(notetypeID: Int64, notetypeName: String, fieldIndex: Int) throws -> [[Int64]] {
        let escaped = notetypeName.replacingOccurrences(of: "\"", with: "\\\"")
        let ids = try browserSearch("\"note:\(escaped)\"", notes: true)
        var seen = Set<Int64>()
        var groups: [[Int64]] = []
        for id in ids where !seen.contains(id) {
            let note = try getNote(id: id)
            guard fieldIndex < note.fields.count, !note.fields[fieldIndex].isEmpty else { continue }
            let text = note.fields[fieldIndex].replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let twins = try browserSearch("\"dupe:\(notetypeID),\(text)\"", notes: true)
            seen.formUnion(twins)
            seen.insert(id)
            if twins.count > 1 { groups.append(twins) }
        }
        return groups.sorted { ($0.first ?? 0) < ($1.first ?? 0) }
    }
}
