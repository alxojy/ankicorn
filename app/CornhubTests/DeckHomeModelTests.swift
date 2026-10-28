import XCTest
@testable import Cornhub

@MainActor
final class DeckHomeModelTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testSeedsSampleDecksThroughTheEngineIdempotently() async throws {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        await model.load()
        XCTAssertEqual(model.state, .loaded)
        func names(_ tiles: [DeckTile]) -> [String] { tiles.flatMap { [$0.name] + names($0.children) } }
        XCTAssertEqual(names(model.decks), ["HSK 1", "HSK 2", "Verbs"])
    }

    func testOpenFailureShowsEngineMessage() async throws {
        let missing = directory.appending(path: "no/such/folder")
        let model = DeckHomeModel(launch: LaunchOptions(), directory: missing)
        await model.load()
        guard case .failed(let message) = model.state else { return XCTFail("expected failed, got \(model.state)") }
        XCTAssertFalse(message.isEmpty)
    }

    func testLaunchOptionsParseArguments() {
        let options = LaunchOptions(arguments: ["Cornhub", "--seed-sample", "--reset-collection"])
        XCTAssertTrue(options.seedSample)
        XCTAssertTrue(options.resetCollection)
        XCTAssertEqual(LaunchOptions(arguments: ["Cornhub"]), LaunchOptions())
    }

    func testUnburyBringsBuriedCardsBack() async throws {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true, seedBuried: true), directory: directory)
        await model.load()
        let deck = try XCTUnwrap(model.decks.first { $0.name == "HSK 1" })
        let buried = await model.buriedCount(for: deck)
        XCTAssertEqual(buried, 2, "two seeded cards are buried")
        let newBefore = deck.newCount

        let count = await model.unbury(deck)
        XCTAssertEqual(count, 2, "unbury reports how many came back")
        let after = await model.buriedCount(for: deck)
        XCTAssertEqual(after, 0, "nothing is buried afterwards")
        let tile = try XCTUnwrap(model.tile(for: deck.id))
        XCTAssertGreaterThanOrEqual(tile.newCount, newBefore, "the counts include the unburied cards")
        XCTAssertNil(model.actionError)
    }

    func testNothingBuriedWithoutTheSeed() async throws {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        let deck = try XCTUnwrap(model.decks.first { $0.name == "HSK 1" })
        let buried = await model.buriedCount(for: deck)
        XCTAssertEqual(buried, 0)
    }

    func testCreateDeckAndSubdeck() async throws {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        let created = await model.createDeck("  Testdeck ")
        XCTAssertTrue(created)
        let top = try XCTUnwrap(model.decks.first { $0.name == "Testdeck" })
        XCTAssertEqual(model.lastCreatedDeckID, top.id)
        XCTAssertEqual(model.highlightedDeckID, top.id)
        let sub = await model.createDeck("Testdeck::Sub")
        XCTAssertTrue(sub)
        let child = try XCTUnwrap(model.tile(for: top.id)?.children.first)
        XCTAssertEqual(child.fullName, "Testdeck::Sub")
    }

    func testDuplicateNameIsReportedBeforeTheEngine() async throws {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        XCTAssertTrue(model.nameTaken("hsk 2::verbs"), "case-insensitive, subdecks included")
        let created = await model.createDeck("HSK 1")
        XCTAssertFalse(created)
        let count = model.decks.count
        XCTAssertEqual(count, 2, "nothing was created")
        let empty = await model.createDeck("   ")
        XCTAssertFalse(empty)
    }

    func testUndoRemovesTheNewDeck() async throws {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        _ = await model.createDeck("Testdeck")
        XCTAssertNotNil(model.decks.first { $0.name == "Testdeck" })
        await model.undoDelete()
        XCTAssertNil(model.decks.first { $0.name == "Testdeck" })
    }
}
