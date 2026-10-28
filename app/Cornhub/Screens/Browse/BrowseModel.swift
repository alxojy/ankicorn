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

    var hasOtherFilters: Bool { tag != nil || notetype != nil || flag != nil }
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

    /// Wait after the last keystroke before a live search runs.
    var debounce: Duration = .milliseconds(300)
    /// Replaces the engine search (tests only).
    var searchRunner: ((String) async throws -> [Int64])?
    private var searchGeneration = 0
    private var pendingSearch: Task<Void, Never>?

    /// Called when the typed query changes: searches after a short pause, cancelling the pending one.
    func queryDidChange() {
        pendingSearch?.cancel()
        let wait = debounce
        pendingSearch = Task { [weak self] in
            try? await Task.sleep(for: wait)
            guard !Task.isCancelled else { return }
            await self?.search()
        }
    }

    /// Searches now (submit, filters, mode changes), dropping any pending debounced search.
    func searchNow() async {
        pendingSearch?.cancel()
        await search()
    }

    func search() async {
        searchGeneration += 1
        let generation = searchGeneration
        isLoading = true
        defer { if generation == searchGeneration { isLoading = false } }
        let text = searchText
        do {
            let found: [Int64]
            if let searchRunner {
                found = try await searchRunner(text)
            } else {
                found = try await backend.browserSearch(text, notes: notesMode, sortColumn: sortKey, reverse: reverse)
            }
            guard generation == searchGeneration else { return }
            ids = found
            rows = [:]
            selection.formIntersection(ids)
        } catch {
            guard generation == searchGeneration else { return }
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

    /// Scope Browse to a deck by id (the engine's `deck:` search includes subdecks).
    func scope(toDeckID id: Int64) async {
        if decks.isEmpty { decks = (try? await backend.deckNames()) ?? [] }
        guard let name = decks.first(where: { $0.id == id })?.name else { return }
        deck = name
        await search()
    }

    var countLine: String {
        let noun = notesMode ? (ids.count == 1 ? "note" : "notes") : (ids.count == 1 ? "card" : "cards")
        return "\(ids.count) \(noun)" + (deck.map { " in \($0.split(separator: ":").last.map(String.init) ?? $0)" } ?? "")
    }

    /// Notes and cards a delete of the selection would remove, for the confirmation text.
    func deleteSummary() async -> (notes: Int, cards: Int) {
        let chosen = selectedOrdered
        guard let notes = try? await noteIDs(chosen) else { return (chosen.count, chosen.count) }
        let cards = (try? await backend.cardIDs(ofNotes: notes).count) ?? chosen.count
        return (notes.count, cards)
    }

    /// Whether the last change can be undone, for the Undo toast.
    func undoLast() async {
        do {
            try await backend.undo()
            changeCount += 1
            await search()
        } catch { errorMessage = "\(error)" }
    }

    func clearFilters() async {
        deck = nil; tag = nil; notetype = nil; flag = nil
        await search()
    }

    // MARK: Ids

    private var selectedOrdered: [Int64] { ids.filter { selection.contains($0) } }

    func selectedNoteIDs() async throws -> [Int64] { try await noteIDs(selectedOrdered) }

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

    var deletedNotice: String?

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
                let notes = try await noteIDs(chosen)
                try await backend.deleteNotes(noteIDs: notes)
                deletedNotice = "Deleted \(notes.count) \(notes.count == 1 ? "note" : "notes")"
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
