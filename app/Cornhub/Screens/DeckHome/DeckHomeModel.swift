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
    private(set) var importState = ImportState.idle

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

    /// Reopens the collection after a full sync transfer closed it.
    func reopen() async throws {
        guard let backend else { return }
        try await backend.openCollection(path: collectionURL)
        try await fetch(backend)
        state = .loaded
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

    func setCollapsed(_ deckID: Int64, _ collapsed: Bool) async {
        guard let backend else { return }
        try? await backend.setDeckCollapsed(deckID: deckID, collapsed: collapsed)
        await refresh()
    }

    private func fetch(_ backend: Backend) async throws {
        let tree = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        decks = DeckTile.tiles(from: tree)
        doneToday = Int((try? await backend.graphs(search: "rated:1", days: 1).today.answerCount) ?? 0)
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
