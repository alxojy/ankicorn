import XCTest

@testable import Cornhub

final class ImportedMediaTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// The folder `openCollection` gives the engine for `collection.anki2` in `folder`.
    private func engineMediaFolder(_ folder: URL) -> URL {
        folder.appending(path: "collection.anki2").deletingPathExtension().appendingPathExtension("media")
    }

    func testAppMediaFolderIsTheEnginesMediaFolder() {
        XCTAssertEqual(
            engineMediaFolder(URL.documentsDirectory).standardizedFileURL, MediaSchemeHandler.mediaFolder.standardizedFileURL,
            "the scheme handler serves the folder the engine imports and syncs media into")
    }

    func testApkgBuiltFromFixtureBringsItsMediaWhereTheSchemeHandlerServes() async throws {
        let sourceDir = directory.appending(path: "source")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        let source = try Backend()
        try await source.openCollection(path: sourceDir.appending(path: "collection.anki2"))
        try await source.addDeck(name: "Imported")
        try await source.seedImportedFixtures(deckName: "Imported", mediaFolder: engineMediaFolder(sourceDir))
        let package = directory.appending(path: "fixture.apkg")
        let exported = try await source.exportAnkiPackage(to: package, scope: .wholeCollection, withScheduling: false, withMedia: true)
        XCTAssertEqual(exported, 2)
        try await source.closeCollection()

        let targetDir = directory.appending(path: "target")
        try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        let target = try Backend()
        try await target.openCollection(path: targetDir.appending(path: "collection.anki2"))
        let summary = try await target.importAnkiPackage(path: package)
        XCTAssertEqual(summary.new, 2)

        let media = engineMediaFolder(targetDir)
        for name in [ImportedFixtures.imageFile, ImportedFixtures.soundFile, ImportedFixtures.sentenceSoundFile] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: media.appending(path: name).path), "\(name) imported")
        }
        // The scheme handler resolves a card's <img src> against the same layout.
        let url = try XCTUnwrap(URL(string: "cornhub://media/\(ImportedFixtures.imageFile)"))
        XCTAssertEqual(MediaSchemeHandler.fileURL(for: url), MediaSchemeHandler.mediaFolder.appending(path: ImportedFixtures.imageFile))
        try await target.closeCollection()
    }
}
