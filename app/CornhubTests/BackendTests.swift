import XCTest
@testable import Cornhub

final class BackendTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private var collectionURL: URL { directory.appending(path: "collection.anki2") }

    func testEngineErrorBeforeCollectionIsOpen() async throws {
        let backend = try Backend()
        do {
            _ = try await backend.deckTree()
            XCTFail("deck_tree must fail without an open collection")
        } catch let error as BackendError {
            XCTAssertFalse(error.message.isEmpty)
            XCTAssertEqual(error.kind, .invalidInput)
            XCTAssertEqual(error.errorDescription, error.message)
        }
    }

    func testRepeatedOpenAndClose() async throws {
        let backend = try Backend()
        for _ in 0..<3 {
            try await backend.openCollection(path: collectionURL)
            _ = try await backend.deckTree()
            try await backend.closeCollection()
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: collectionURL.path))
    }

    @MainActor
    func testCallRunsOffTheMainThreadWhenAwaitedFromMainActor() async throws {
        let backend = try Backend()
        XCTAssertTrue(Thread.isMainThread)
        try await backend.openCollection(path: collectionURL)
        let ranOnMain = try await backend.deckTreeRanOnMainThread()
        XCTAssertFalse(ranOnMain)
        try await backend.closeCollection()
    }

    func testUndecodableErrorBytesBecomeInvalidInput() {
        let error = BackendError.decode(Data([0xFF, 0xFF, 0xFF]))
        XCTAssertEqual(error.kind, .invalidInput)
    }
}

extension Backend {
    /// Runs a real engine call and reports whether it executed on the main thread.
    func deckTreeRanOnMainThread() throws -> Bool {
        _ = try deckTree()
        return Thread.isMainThread
    }
}
