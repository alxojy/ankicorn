import Foundation
import Observation

/// Opens the collection through the engine and holds the deck tree for the Phase 0 screen.
@MainActor
@Observable
final class DeckTreeModel {
    enum State: Equatable {
        case loading
        case loaded([DeckRow])
        case failed(String)
    }

    static let sampleDecks = ["HSK 1", "HSK 2", "HSK 2::Verbs"]

    private(set) var state = State.loading
    private let launch: LaunchOptions
    private let collectionURL: URL
    private var backend: Backend?

    init(launch: LaunchOptions, directory: URL? = nil) {
        self.launch = launch
        let folder = directory ?? URL.documentsDirectory
        collectionURL = folder.appending(path: "collection.anki2")
    }

    func load() async {
        state = .loading
        do {
            if launch.resetCollection { removeCollectionFiles() }
            let backend = try backend ?? Backend()
            self.backend = backend
            try await backend.openCollection(path: collectionURL)
            if launch.seedSample { try await seedSampleDecks(backend) }
            let tree = try await backend.deckTree()
            state = .loaded(DeckRow.rows(from: tree))
            try await backend.closeCollection()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func seedSampleDecks(_ backend: Backend) async throws {
        let existing = Set(DeckRow.rows(from: try await backend.deckTree()).map(\.fullName))
        for name in Self.sampleDecks where !existing.contains(name) {
            try await backend.addDeck(name: name)
        }
    }

    private func removeCollectionFiles() {
        let fileManager = FileManager.default
        let base = collectionURL.deletingPathExtension()
        let names = [collectionURL, base.appendingPathExtension("media"), base.appendingPathExtension("media.db2")]
        for url in names + ["-wal", "-shm"].map({ URL(fileURLWithPath: collectionURL.path + $0) }) {
            try? fileManager.removeItem(at: url)
        }
    }
}
