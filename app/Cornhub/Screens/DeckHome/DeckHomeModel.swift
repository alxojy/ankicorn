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

    private(set) var state = State.loading
    private(set) var decks: [DeckTile] = []
    private(set) var studiedToday = ""
    private(set) var syncStatus = "Not synced yet"

    private let launch: LaunchOptions
    private let collectionURL: URL
    private var backend: Backend?

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
            if launch.seedSample { try await seedSampleDecks(backend) }
            try await fetch(backend)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Pull to refresh. Sync arrives in Phase 2, so this reloads the counts.
    func refresh() async {
        guard let backend else { return await load() }
        do {
            try await fetch(backend)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func counts(for deckID: Int64) async -> (new: Int, review: Int)? {
        guard let backend, let counts = try? await backend.countsForDeckToday(deckID: deckID) else { return nil }
        return (Int(counts.new), Int(counts.review))
    }

    func setCollapsed(_ deckID: Int64, _ collapsed: Bool) async {
        guard let backend else { return }
        try? await backend.setDeckCollapsed(deckID: deckID, collapsed: collapsed)
        await refresh()
    }

    private func fetch(_ backend: Backend) async throws {
        let tree = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        decks = DeckTile.tiles(from: tree)
        studiedToday = (try? await backend.studiedToday()) ?? ""
    }

    private func seedSampleDecks(_ backend: Backend) async throws {
        let existing = Set(DeckRow.rows(from: try await backend.deckTree()).map(\.fullName))
        for name in DeckTreeModel.sampleDecks where !existing.contains(name) {
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
