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
}
