import XCTest
@testable import Cornhub

@MainActor
final class DeckTreeModelTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testSeedsSampleDecksThroughTheEngineIdempotently() async throws {
        let model = DeckTreeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        await model.load()
        guard case .loaded(let rows) = model.state else { return XCTFail("expected loaded, got \(model.state)") }
        XCTAssertEqual(rows.map(\.fullName), ["HSK 1", "HSK 2", "HSK 2::Verbs"])
    }

    func testEmptyCollectionWithoutSeed() async throws {
        let model = DeckTreeModel(launch: LaunchOptions(), directory: directory)
        await model.load()
        guard case .loaded(let rows) = model.state else { return XCTFail("expected loaded, got \(model.state)") }
        XCTAssertTrue(rows.allSatisfy { $0.fullName == "Default" }, "only the engine's Default deck may exist")
    }

    func testOpenFailureShowsEngineMessage() async throws {
        let missing = directory.appending(path: "no/such/folder")
        let model = DeckTreeModel(launch: LaunchOptions(), directory: missing)
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
}
