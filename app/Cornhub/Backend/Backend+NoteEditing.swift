import Foundation

extension Backend {
    /// `defaults_for_adding`: the deck and note type the Add card screen starts with.
    func defaultsForAdding(homeDeckID: Int64 = 0) throws -> Anki_Notes_DeckAndNotetype {
        var request = Anki_Notes_DefaultsForAddingRequest()
        request.homeDeckOfCurrentReviewCard = homeDeckID
        return try call(service: ServiceIndex.Notes.service, method: ServiceIndex.Notes.defaultsForAdding, request)
    }

    /// `get_deck_names`: normal decks only, for the deck picker.
    func deckNames() throws -> [Anki_Decks_DeckNameId] {
        var request = Anki_Decks_GetDeckNamesRequest()
        request.skipEmptyDefault = true
        request.includeFiltered = false
        let names: Anki_Decks_DeckNames = try call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.getDeckNames, request)
        return names.entries
    }

    /// `all_tags`: every tag in the collection, for suggestions.
    func allTags() throws -> [String] {
        let tags: Anki_Generic_StringList = try call(
            service: ServiceIndex.Tags.service, method: ServiceIndex.Tags.allTags, Anki_Generic_Empty())
        return tags.vals
    }

    /// `add_media_file`: stores `data` in the media folder and returns the name it was stored under.
    func addMediaFile(desiredName: String, data: Data) throws -> String {
        var request = Anki_Media_AddMediaFileRequest()
        request.desiredName = desiredName
        request.data = data
        let name: Anki_Generic_String = try call(
            service: ServiceIndex.Media.service, method: ServiceIndex.Media.addMediaFile, request)
        return name.val
    }
}
