import XCTest

@testable import Cornhub

final class NotetypeStyleTests: XCTestCase {
    private let original = ImportedFixtures.lightCSS

    func testGeneratedCSSHasNoCardBackgroundAndReadsAsInk() {
        let css = NotetypeStyle.generate(from: original)
        XCTAssertEqual(CardStyle.decide(css: css), .ink, "no opaque .card background outside the comment")
        XCTAssertFalse(NotetypeStyle.setsOwnBackground(css: css))
        XCTAssertTrue(NotetypeStyle.setsOwnBackground(css: original))
    }

    func testNightModeRulesAndDesktopLightRulesArePresent() {
        let css = NotetypeStyle.generate(from: original)
        XCTAssertTrue(css.contains(".nightMode .card, .night_mode .card"))
        XCTAssertTrue(css.contains(".nightMode .hanzi, .night_mode .hanzi"))
        XCTAssertTrue(css.contains(CardWebView.hex(Theme.text)), "Ink text colour in night mode")
        XCTAssertTrue(css.contains("color: #1C1C1E"), "dark text in desktop light mode")
    }

    func testClassNamesAreKeptAndMappedToRoles() {
        let roles = Dictionary(uniqueKeysWithValues: NotetypeStyle.classes(in: original))
        XCTAssertEqual(roles[".hanzi"], .headword)
        XCTAssertEqual(roles[".pinyin"], .pinyin)
        XCTAssertEqual(roles[".english"], .meaning)
        XCTAssertEqual(roles[".meaningSent"], .meaning)
        XCTAssertEqual(roles[".description"], .description)
        XCTAssertEqual(roles[".sentence"], .sentence)
        let css = NotetypeStyle.generate(from: original)
        for name in [".hanzi", ".pinyin", ".english", ".sentence", ".description"] {
            XCTAssertTrue(css.contains("\(name) {"), "\(name) is kept")
        }
        XCTAssertFalse(CardStyle.strippingComments(css).contains("Kaiti"), "old fonts are dropped outside the comment")
    }

    func testOldCSSIsRecoverable() {
        let css = NotetypeStyle.generate(from: original)
        XCTAssertTrue(css.contains("/* cornhub: previous css"))
        XCTAssertTrue(NotetypeStyle.canRestore(css: css))
        XCTAssertEqual(NotetypeStyle.restored(from: css), original)
        XCTAssertFalse(NotetypeStyle.canRestore(css: original))
    }

    func testCommentTerminatorInOldCSSSurvivesRoundTrip() {
        let tricky = ".card { color: red; } /* note */ .x { color: blue }"
        XCTAssertEqual(NotetypeStyle.restored(from: NotetypeStyle.generate(from: tricky)), tricky)
    }

    func testGeneratingTwiceIsStable() {
        let once = NotetypeStyle.generate(from: original)
        XCTAssertEqual(NotetypeStyle.generate(from: once), once)
    }
}

final class NotetypeStyleEngineTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws { directory = try makeTempDirectory() }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: directory) }

    func testApplyUndoAndRestoreThroughTheEngine() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let deck = try await backend.addDeck(name: "Fixture")
        let stock = try await backend.stockNotetypeJSON(kind: .basic)
        let ntid = try await backend.addNotetype(
            json: try ImportedFixtures.json(basedOn: stock, name: "HSK+ shape", css: ImportedFixtures.lightCSS))
        try await backend.addNote(
            notetypeID: ntid, deckID: deck, fields: ImportedFixtures.fieldValues(ImportedFixtures.lightNote, withMedia: false))
        let found = try await backend.browserSearch("\"note:HSK+ shape\"", notes: false)
        let card = try XCTUnwrap(found.first)

        var notetype = try await backend.getNotetype(id: ntid)
        let before = notetype.config.css
        let rendered = try await backend.renderExistingCard(id: card).css
        XCTAssertEqual(rendered, before)

        notetype.config.css = NotetypeStyle.generate(from: before)
        try await backend.updateNotetype(notetype)
        let styled = try await backend.renderExistingCard(id: card).css
        XCTAssertEqual(styled, notetype.config.css, "the card renders with the new CSS")
        XCTAssertEqual(CardStyle.decide(css: styled), .ink)

        try await backend.undo()
        let undone = try await backend.getNotetype(id: ntid).config.css
        XCTAssertEqual(undone, before, "engine undo restores the old CSS")

        notetype = try await backend.getNotetype(id: ntid)
        notetype.config.css = NotetypeStyle.generate(from: before)
        try await backend.updateNotetype(notetype)
        notetype.config.css = try XCTUnwrap(NotetypeStyle.restored(from: notetype.config.css))
        try await backend.updateNotetype(notetype)
        let back = try await backend.renderExistingCard(id: card).css
        XCTAssertEqual(back, before, "restore from the comment works")
        try await backend.closeCollection()
    }
}
