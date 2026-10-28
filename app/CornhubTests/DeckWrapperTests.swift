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

        let tree = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        let names = tree.children.map(\.name)
        XCTAssertTrue(names.contains("HSK 1"))
        XCTAssertTrue(names.contains("HSK 2"))
        try await backend.closeCollection()
    }

    func testNestedDeckIsFlattenedWithLevel() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        try await backend.addDeck(name: "HSK 2::Verbs")
        let rows = DeckRow.rows(from: try await backend.deckTree(now: Int64(Date().timeIntervalSince1970)))
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

    func testRenameDeckShowsNewNameInTree() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let id = try await backend.addDeck(name: "HSK 2")
        try await backend.renameDeck(id: id, name: "HSK 2b")
        let names = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970)).children.map(\.name)
        XCTAssertTrue(names.contains("HSK 2b"))
        XCTAssertFalse(names.contains("HSK 2"))
        try await backend.closeCollection()
    }

    func testRenameWithSeparatorMakesSubdeck() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        try await backend.addDeck(name: "HSK 1")
        let id = try await backend.addDeck(name: "Verbs")
        try await backend.renameDeck(id: id, name: "HSK 1::Verbs")
        let tree = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        XCTAssertEqual(tree.children.map(\.name), ["HSK 1"])
        XCTAssertEqual(tree.children.first?.children.map(\.name), ["Verbs"])
        XCTAssertEqual(DeckTile.tiles(from: tree).first?.children.first?.fullName, "HSK 1::Verbs")
        try await backend.closeCollection()
    }

    func testRemoveDeckReturnsCardCountAndUndoRestoresIt() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let id = try await backend.addDeck(name: "HSK 2")
        try await backend.seedSampleNotes(deckNames: ["HSK 2"])
        let tree = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        let node = try XCTUnwrap(tree.children.first { $0.deckID == id })
        let cards = Int(node.totalIncludingChildren)
        XCTAssertGreaterThan(cards, 0)

        let removed = try await backend.removeDecks(ids: [id])
        XCTAssertEqual(removed, cards)
        let afterDelete = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        XCTAssertFalse(afterDelete.children.contains { $0.deckID == id })

        try await backend.undo()
        let afterUndo = try await backend.deckTree(now: Int64(Date().timeIntervalSince1970))
        let restored = try XCTUnwrap(afterUndo.children.first { $0.deckID == id })
        XCTAssertEqual(Int(restored.totalIncludingChildren), cards)
        try await backend.closeCollection()
    }
}

final class ChineseNotetypeAnswerColumnTests: XCTestCase {
    func testBrowserAnswerColumnDropsQuestionAndKeepsSeparators() async throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let deck = try await backend.addDeck(name: "Test")
        let notetype = try await backend.ensureChineseNotetype()
        var fields = Array(repeating: "", count: ChineseNotetype.fields.count)
        fields[ChineseNotetype.Field.hanzi] = "明天再见！"
        fields[ChineseNotetype.Field.pinyin] = "Míngtiān zàijiàn!"
        fields[ChineseNotetype.Field.english] = "See you tomorrow"
        fields[ChineseNotetype.Field.example] = "明天见。"
        fields[ChineseNotetype.Field.examplePinyin] = "Míngtiān jiàn."
        fields[ChineseNotetype.Field.exampleEnglish] = "See you."
        try await backend.addNote(notetypeID: notetype, deckID: deck, fields: fields)
        try await backend.setBrowserNotesMode(false)
        try await backend.setActiveBrowserColumns(["question", "answer"])
        let ids = try await backend.browserSearch("deck:Test", notes: false)
        XCTAssertEqual(ids.count, 2)
        var answers: [String] = []
        for id in ids {
            let row = try await backend.browserRow(id: id)
            let question = row.cells[0].text, answer = row.cells[1].text
            answers.append(answer)
            XCTAssertFalse(answer.hasPrefix(question), "answer repeats question: \(answer)")
            XCTAssertFalse(answer.contains("Míngtiān zàijiàn!See"), answer)
            XCTAssertFalse(answer.contains("明天见。Míngtiān"), answer)
            XCTAssertFalse(answer.contains("jiàn.See"), answer)
        }
        XCTAssertTrue(answers.contains { $0.hasPrefix("Míngtiān zàijiàn!") && $0.contains("See you tomorrow") })
        XCTAssertTrue(answers.contains { $0.hasPrefix("明天再见！") })
        try await backend.closeCollection()
    }
}
