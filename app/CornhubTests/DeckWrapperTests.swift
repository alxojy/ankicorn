import XCTest
@testable import Cornhub

final class DeckWrapperTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testCreatesDecksAndReadsThemBack() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let first = try await backend.addDeck(name: "HSK 1")
        let second = try await backend.addDeck(name: "HSK 2")
        XCTAssertNotEqual(first, 0)
        XCTAssertNotEqual(first, second)

        let tree = try await backend.deckTree()
        let names = tree.children.map(\.name)
        XCTAssertTrue(names.contains("HSK 1"))
        XCTAssertTrue(names.contains("HSK 2"))
        try await backend.closeCollection()
    }

    func testNestedDeckIsFlattenedWithLevel() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        try await backend.addDeck(name: "HSK 2::Verbs")
        let rows = DeckRow.rows(from: try await backend.deckTree())
        let verbs = try XCTUnwrap(rows.first { $0.fullName == "HSK 2::Verbs" })
        XCTAssertEqual(verbs.name, "Verbs")
        XCTAssertEqual(verbs.level, 2)
        XCTAssertTrue(rows.contains { $0.fullName == "HSK 2" && $0.level == 1 })
        try await backend.closeCollection()
    }

    func testAddedDeckPointsAtARealDeckConfig() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let id = try await backend.addDeck(name: "HSK 3")
        var request = Anki_Decks_DeckId()
        request.did = id
        let deck: Anki_Decks_Deck = try await backend.call(
            service: ServiceIndex.Decks.service, method: ServiceIndex.Decks.getDeck, request)
        XCTAssertNotEqual(deck.normal.configID, 0)
        let config = try await backend.getDeckConfig(id: deck.normal.configID)
        XCTAssertEqual(config.id, deck.normal.configID)
        try await backend.closeCollection()
    }
}
