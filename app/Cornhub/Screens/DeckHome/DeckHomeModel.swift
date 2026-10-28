import Foundation
import Observation

/// Opens the collection through the engine and holds everything the Decks home shows.
@MainActor
@Observable
final class DeckHomeModel {
    enum State: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    enum ImportState: Equatable {
        case idle
        case importing(String)
        case done(ImportSummary)
        case failed(String)
    }

    static let sampleDecks = ["HSK 1", "HSK 2", "HSK 2::Verbs"]

    private(set) var state = State.loading
    private(set) var decks: [DeckTile] = []
    private(set) var doneToday = 0
    private(set) var streak = 0
    private(set) var importState = ImportState.idle
    /// Set after a delete so the screen can show the Undo toast.
    private(set) var deletedNotice: String?
    var actionError: String?
    /// The most recently created deck, so Add card can default to it.
    private(set) var lastCreatedDeckID: Int64?
    /// Top-level tile to scroll to and highlight briefly after a create.
    private(set) var highlightedDeckID: Int64?

    private let launch: LaunchOptions
    private let collectionURL: URL
    private(set) var backend: Backend?

    init(launch: LaunchOptions, directory: URL? = nil) {
        self.launch = launch
        collectionURL = (directory ?? URL.documentsDirectory).appending(path: "collection.anki2")
    }

    var newTotal: Int { decks.reduce(0) { $0 + $1.newCount } }
    var learningTotal: Int { decks.reduce(0) { $0 + $1.learningCount } }
    var reviewTotal: Int { decks.reduce(0) { $0 + $1.reviewCount } }
    var dueTotal: Int { newTotal + learningTotal + reviewTotal }
    /// Rough estimate for the hero line: about eight seconds a card.
    var estimatedMinutes: Int { Int((Double(dueTotal) * 8 / 60).rounded(.up)) }

    func load() async {
        if case .loaded = state { return await refresh() }
        state = .loading
        do {
            if launch.resetCollection { removeCollectionFiles() }
            let backend = try backend ?? Backend()
            self.backend = backend
            try await backend.openCollection(path: collectionURL)
            await repairDeckConfigsOnce(backend)
            try await backend.ensureChineseNotetype()
            if launch.seedSample {
                try await seedSampleDecks(backend)
                try await backend.seedSampleNotes(deckNames: DeckHomeModel.sampleDecks)
                if launch.seedFourSubdecks {
                    for index in 1...3 { _ = try await backend.addDeck(name: "HSK 2::Topic \(index)") }
                }
                if launch.seedManySubdecks {
                    for index in 1...12 { _ = try await backend.addDeck(name: "HSK 2::Topic \(index)") }
                }
                if launch.seedBuried { try await backend.buryCards(deckName: DeckHomeModel.sampleDecks[0], limit: 2) }
            } else if launch.seedImported || launch.seedLongCard || launch.seedPictureCard {
                try await seedSampleDecks(backend)
                try await backend.seedImportedFixtures(
                    deckName: DeckHomeModel.sampleDecks[0], withImage: !launch.dropFixtureImage,
                    longCard: launch.seedLongCard, pictureCardLines: launch.seedPictureCard ? 5 : 0)
            } else if launch.seedOneDue || launch.seedNoDue {
                try await seedSampleDecks(backend)
                if launch.seedOneDue { try await backend.seedOneDueNote(deckName: DeckHomeModel.sampleDecks[0]) }
            }
            try await fetch(backend)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Decks added by earlier builds point at a deck config that does not exist. The engine's database check
    /// repairs them; run it once per install of this fix.
    private func repairDeckConfigsOnce(_ backend: Backend) async {
        let key = "deckConfigRepair.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        if (try? await backend.checkDatabase()) != nil { UserDefaults.standard.set(true, forKey: key) }
    }

    /// Reloads the counts (a sync calls this when it finishes).
    func refresh() async {
        guard let backend else { return await load() }
        do {
            try await fetch(backend)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Imports an `.apkg` or `.colpkg` picked from Files or opened from another app, and refreshes the decks.
    func importPackage(_ url: URL) async {
        if backend == nil { await load() }
        guard let backend else { return }
        let isCollection = url.pathExtension.lowercased() == "colpkg"
        importState = .importing(isCollection ? "Replacing your collection" : "Importing \(url.lastPathComponent)")
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            // The engine reads a plain file path, so copy out of the security-scoped location first.
            let local = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString).appending(path: url.lastPathComponent)
            try FileManager.default.createDirectory(
                at: local.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: local)
            defer { try? FileManager.default.removeItem(at: local.deletingLastPathComponent()) }
            let summary =
                isCollection
                ? try await backend.importCollectionPackage(path: local, collection: collectionURL)
                : try await backend.importAnkiPackage(path: local)
            try await backend.ensureChineseNotetype()
            try await fetch(backend)
            importState = .done(summary)
        } catch {
            importState = .failed(error.localizedDescription)
        }
    }

    func dismissImport() { importState = .idle }

    /// The deck's tile from the latest `deck_tree`, so the overview matches the home tiles.
    func tile(for deckID: Int64) -> DeckTile? {
        func find(_ tiles: [DeckTile]) -> DeckTile? {
            for tile in tiles {
                if tile.id == deckID { return tile }
                if let hit = find(tile.children) { return hit }
            }
            return nil
        }
        return find(decks)
    }

    /// The deck's tile by full "Parent::Child" name.
    func tile(fullName: String) -> DeckTile? {
        func find(_ tiles: [DeckTile]) -> DeckTile? {
            for tile in tiles {
                if tile.fullName == fullName { return tile }
                if let hit = find(tile.children) { return hit }
            }
            return nil
        }
        return find(decks)
    }

    func setCollapsed(_ deckID: Int64, _ collapsed: Bool) async {
        guard let backend else { return }
        try? await backend.setDeckCollapsed(deckID: deckID, collapsed: collapsed)
        await refresh()
    }

    /// Deleting the Default deck is refused by the engine, so it is not offered.
    func canDelete(_ deck: DeckTile) -> Bool { deck.id != 1 }

    func rename(_ deck: DeckTile, to name: String) async {
        guard let backend else { return }
        do {
            try await backend.renameDeck(id: deck.id, name: name.trimmingCharacters(in: .whitespaces))
            await refresh()
        } catch { actionError = error.localizedDescription }
    }

    func delete(_ deck: DeckTile) async {
        guard let backend, canDelete(deck) else { return }
        do {
            try await backend.removeDecks(ids: [deck.id])
            deletedNotice = "Deleted \(deck.name)"
            await refresh()
        } catch { actionError = error.localizedDescription }
    }

    func undoDelete() async {
        deletedNotice = nil
        guard let backend else { return }
        do {
            try await backend.undo()
            await refresh()
        } catch { actionError = error.localizedDescription }
    }

    /// How many cards in the deck (with subdecks) are buried, from the engine.
    func buriedCount(for deck: DeckTile) async -> Int {
        guard let backend else { return 0 }
        return (try? await backend.buriedCardIDs(deckName: deck.fullName.isEmpty ? deck.name : deck.fullName).count) ?? 0
    }

    /// Unburies the deck's cards and returns how many came back; failures land in `actionError`.
    func unbury(_ deck: DeckTile) async -> Int? {
        guard let backend else { return nil }
        let before = await buriedCount(for: deck)
        do {
            try await backend.unburyDeck(id: deck.id)
            await refresh()
            let after = await buriedCount(for: deck)
            return max(before - after, 0)
        } catch {
            actionError = error.localizedDescription
            return nil
        }
    }

    /// The name as the engine will store it: surrounding whitespace removed.
    static func cleanedDeckName(_ raw: String) -> String { raw.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// True when a deck with this full name (case-insensitive, as Anki compares) is already in the tree.
    func nameTaken(_ raw: String) -> Bool {
        let name = DeckHomeModel.cleanedDeckName(raw).lowercased()
        func contains(_ tiles: [DeckTile]) -> Bool {
            tiles.contains { $0.fullName.lowercased() == name || contains($0.children) }
        }
        return contains(decks)
    }

    /// Creates the deck through the engine (`Parent::Child` makes a subdeck). Returns false and sets `actionError`
    /// on failure; the caller checks `nameTaken` first so the engine never silently renames a duplicate.
    @discardableResult
    func createDeck(_ raw: String) async -> Bool {
        let name = DeckHomeModel.cleanedDeckName(raw)
        guard let backend, !name.isEmpty, !nameTaken(name) else { return false }
        do {
            let id = try await backend.addDeck(name: name)
            lastCreatedDeckID = id
            await refresh()
            let root = name.components(separatedBy: "::").first?.lowercased()
            highlightedDeckID = decks.first { $0.fullName.lowercased() == root }?.id
            deletedNotice = "Created \(name)"
            return true
        } catch {
            actionError = error.localizedDescription
            return false
        }
    }

    func clearHighlight() { highlightedDeckID = nil }

    func dismissDeletedNotice() { deletedNotice = nil }

    private func fetch(_ backend: Backend) async throws {
        let tree = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        decks = DeckTile.tiles(from: tree)
        doneToday = Int((try? await backend.graphs(search: "rated:1", days: 1).today.answerCount) ?? 0)
        if let graphs = try? await backend.graphs(search: "", days: 365) {
            streak = StudyStreak.days(StudyStreak.dailyCounts(graphs.reviews.count, days: 112))
        }
    }

    private func seedSampleDecks(_ backend: Backend) async throws {
        let existing = Set(DeckRow.rows(from: try await backend.deckTree()).map(\.fullName))
        for name in DeckHomeModel.sampleDecks where !existing.contains(name) {
            try await backend.addDeck(name: name)
        }
    }

    private func removeCollectionFiles() {
        let base = collectionURL.deletingPathExtension()
        let names = [collectionURL, base.appendingPathExtension("media"), base.appendingPathExtension("media.db2")]
        for url in names + ["-wal", "-shm"].map({ URL(fileURLWithPath: collectionURL.path + $0) }) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
