import XCTest
@testable import Cornhub

@MainActor
final class BrowseLiveSearchTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeModel() async throws -> BrowseModel {
        let home = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await home.load()
        let backend = try XCTUnwrap(home.backend)
        return BrowseModel(backend: backend)
    }

    func testRapidQueryChangesRunOneSearchForTheFinalText() async throws {
        let model = try await makeModel()
        model.debounce = .milliseconds(50)
        var searched: [String] = []
        model.searchRunner = { text in searched.append(text); return [1] }
        for text in ["h", "he", "hel", "hello"] {
            model.query = text
            model.queryDidChange()
        }
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(searched.count, 1)
        XCTAssertTrue(searched.first?.contains("hello") == true)
    }

    func testOlderSearchFinishingLateDoesNotOverwriteNewerResults() async throws {
        let model = try await makeModel()
        model.searchRunner = { text in
            if text.contains("slow") { try await Task.sleep(for: .milliseconds(300)); return [1] }
            return [2, 3]
        }
        model.query = "slow"
        let older = Task { await model.search() }
        try await Task.sleep(for: .milliseconds(50))
        model.query = "fast"
        await model.search()
        await older.value
        XCTAssertEqual(model.ids, [2, 3])
    }
}
