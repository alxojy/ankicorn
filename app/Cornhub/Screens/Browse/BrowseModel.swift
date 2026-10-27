import Foundation
import Observation

/// State of the Browse tab. Searching, rows, sorting and every action are engine calls.
@MainActor @Observable
final class BrowseModel {
    let backend: Backend
    var query = ""
    var notesMode = false { didSet { if oldValue != notesMode { Task { await switchMode() } } } }
    var sortKey = ""
    var reverse = false
    var deck: String?
    var tag: String?
    var notetype: String?
    var flag: Int?
    private(set) var ids: [Int64] = []
    private(set) var rows: [Int64: Anki_Search_BrowserRow] = [:]
    private(set) var columns: [Anki_Search_BrowserColumns.Column] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var selecting = false
    var selection: Set<Int64> = []
    private(set) var changeCount = 0

    // Sheet data for the filter sheet and pickers.
    private(set) var decks: [Anki_Decks_DeckNameId] = []
    private(set) var tags: [String] = []
    private(set) var notetypes: [Anki_Notetypes_NotetypeNameId] = []

    init(backend: Backend) { self.backend = backend }

    var hasFilters: Bool { deck != nil || tag != nil || notetype != nil || flag != nil }
    var sortableColumns: [Anki_Search_BrowserColumns.Column] {
        columns.filter { (notesMode ? $0.sortingNotes : $0.sortingCards) != .none }
    }

    func label(_ column: Anki_Search_BrowserColumns.Column) -> String {
        notesMode ? column.notesModeLabel : column.cardsModeLabel
    }

    /// The search text the engine runs: typed query plus the filter sheet's choices.
    var searchText: String {
        var parts: [String] = []
        if let deck { parts.append("\"deck:\(Self.escape(deck))\"") }
        if let tag { parts.append("\"tag:\(Self.escape(tag))\"") }
        if let notetype { parts.append("\"note:\(Self.escape(notetype))\"") }
        if let flag { parts.append("flag:\(flag)") }
        let typed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty { parts.append(typed) }
        return parts.joined(separator: " ")
    }

    static func escape(_ text: String) -> String {
        var result = ""
        for character in text {
            if "\\\"*_".contains(character) { result.append("\\") }
            result.append(character)
        }
        return result
    }

    func load() async {
        do {
            columns = try await backend.allBrowserColumns()
            decks = try await backend.deckNames()
            tags = try await backend.allTags()
            notetypes = try await backend.notetypeNames()
            try await applyColumns()
        } catch { errorMessage = "\(error)" }
        await search()
    }

    private func applyColumns() async throws {
        try await backend.setBrowserNotesMode(notesMode)
        try await backend.setActiveBrowserColumns(
            notesMode ? ["noteFld", "noteTags", "note"] : ["question", "answer", "deck"])
    }

    private func switchMode() async {
        sortKey = ""
        selection = []
        do { try await applyColumns() } catch { errorMessage = "\(error)" }
        await search()
    }

    func search() async {
        isLoading = true
        defer { isLoading = false }
        do {
            ids = try await backend.browserSearch(searchText, notes: notesMode, sortColumn: sortKey, reverse: reverse)
            rows = [:]
            selection.formIntersection(ids)
        } catch {
            ids = []
            errorMessage = "\(error)"
        }
    }

    func loadRow(_ id: Int64) async {
        guard rows[id] == nil, let row = try? await backend.browserRow(id: id) else { return }
        rows[id] = row
    }

    func toggle(_ id: Int64) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    func clearFilters() async {
        deck = nil; tag = nil; notetype = nil; flag = nil
        await search()
    }

    // MARK: Ids

    private var selectedOrdered: [Int64] { ids.filter { selection.contains($0) } }

    func cardIDs(_ chosen: [Int64]) async throws -> [Int64] {
        notesMode ? try await backend.cardIDs(ofNotes: chosen) : chosen
    }

    func noteIDs(_ chosen: [Int64]) async throws -> [Int64] {
        guard !notesMode else { return chosen }
        var seen = Set<Int64>()
        var result: [Int64] = []
        for id in chosen {
            let note = try await backend.getCard(id: id).noteID
            if seen.insert(note).inserted { result.append(note) }
        }
        return result
    }

    func note(for id: Int64) async -> Anki_Notes_Note? {
        do {
            let noteID = notesMode ? id : try await backend.getCard(id: id).noteID
            return try await backend.getNote(id: noteID)
        } catch {
            errorMessage = "\(error)"
            return nil
        }
    }

    func previewCardID(for id: Int64) async -> Int64? {
        (try? await cardIDs([id]))?.first
    }

    // MARK: Actions on the selection

    enum Action {
        case changeDeck(Int64)
        case addTags(String), removeTags(String)
        case reposition(start: UInt32, step: UInt32, randomize: Bool, shift: Bool)
        case setDueDate(String)
        case forget
        case suspend(Bool)
        case delete
    }

    func perform(_ action: Action) async {
        let chosen = selectedOrdered
        guard !chosen.isEmpty else { return }
        do {
            switch action {
            case .changeDeck(let deckID):
                try await backend.setDeck(cardIDs: try await cardIDs(chosen), deckID: deckID)
            case .addTags(let text):
                try await backend.changeTags(noteIDs: try await noteIDs(chosen), tags: text, add: true)
            case .removeTags(let text):
                try await backend.changeTags(noteIDs: try await noteIDs(chosen), tags: text, add: false)
            case .reposition(let start, let step, let randomize, let shift):
                try await backend.reposition(
                    cardIDs: try await cardIDs(chosen), start: start, step: step, randomize: randomize, shift: shift)
            case .setDueDate(let days):
                try await backend.setDueDate(cardIDs: try await cardIDs(chosen), days: days)
            case .forget:
                try await backend.forget(cardIDs: try await cardIDs(chosen))
            case .suspend(let on):
                try await backend.suspend(cardIDs: try await cardIDs(chosen), suspend: on)
            case .delete:
                try await backend.deleteNotes(noteIDs: try await noteIDs(chosen))
            }
            changeCount += 1
            selection = []
            selecting = false
            await search()
        } catch {
            errorMessage = "\(error)"
        }
    }
}
