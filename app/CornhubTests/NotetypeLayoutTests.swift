import XCTest

@testable import Cornhub

final class NotetypeLayoutTests: XCTestCase {
    /// The HSK+ field list as seen in the proposal (19 fields); only names, no content.
    static let hskFields = [
        "Key", "Simplified", "Homograph", "Pinyin.1", "Pinyin.2", "Meaning", "Part of speech", "Audio",
        "SentenceSimplified", "SentencePinyin.1", "SentenceMeaning", "SentenceAudio", "SentenceImage", "Traditional",
        "Frequency", "Level", "Notes", "Tags2", "Source"
    ]

    func testGuesserOnHSKPlusFieldNames() {
        let mapping = NotetypeLayout.guess(fields: Self.hskFields)
        XCTAssertEqual(mapping[.hanzi], "Simplified")
        XCTAssertEqual(mapping[.pinyin], "Pinyin.1")
        XCTAssertEqual(mapping[.meaning], "Meaning")
        XCTAssertEqual(mapping[.partOfSpeech], "Part of speech")
        XCTAssertEqual(mapping[.picture], "SentenceImage")
        XCTAssertEqual(mapping[.example], "SentenceSimplified")
        XCTAssertEqual(mapping[.examplePinyin], "SentencePinyin.1")
        XCTAssertEqual(mapping[.exampleMeaning], "SentenceMeaning")
        XCTAssertEqual(mapping[.extra], "Homograph")
        XCTAssertEqual(mapping.audio, ["Audio", "SentenceAudio"])
        XCTAssertTrue(mapping.unmapped(in: Self.hskFields).contains("Frequency"), "unmapped fields are listed")
        XCTAssertTrue(NotetypeLayout.offered(for: Self.hskFields))
        XCTAssertFalse(NotetypeLayout.offered(for: ["Front", "Back"]))
    }

    func testGuesserOnBundledChineseVocab() {
        let mapping = NotetypeLayout.guess(fields: ChineseNotetype.fields)
        XCTAssertEqual(mapping[.hanzi], "Hanzi")
        XCTAssertEqual(mapping[.pinyin], "Pinyin")
        XCTAssertEqual(mapping[.meaning], "English")
        XCTAssertEqual(mapping[.picture], "Picture")
        XCTAssertEqual(mapping[.example], "Example")
        XCTAssertEqual(mapping[.examplePinyin], "Example pinyin")
        XCTAssertEqual(mapping[.exampleMeaning], "Example English")
        XCTAssertEqual(mapping.audio, ["Audio"])
    }

    func testGuesserFallsBackToTheFieldTheFrontShows() {
        let mapping = NotetypeLayout.guess(fields: ["Key", "Front text"], frontTemplate: "{{FrontSide}}{{Front text}}")
        XCTAssertEqual(mapping[.hanzi], "Front text")
    }

    func testGeneratedTemplatesReferenceOnlyExistingFields() {
        var mapping = NotetypeLayout.guess(fields: Self.hskFields)
        mapping.showExampleOnFront = true
        for html in [NotetypeLayout.front(mapping), NotetypeLayout.back(mapping)] {
            for name in NotetypeLayout.referencedFields(in: html) {
                XCTAssertTrue(Self.hskFields.contains(name), "\(name) exists")
            }
        }
        XCTAssertTrue(NotetypeLayout.back(mapping).contains("{{SentenceAudio}}"), "audio tags are kept")
        XCTAssertFalse(NotetypeLayout.front(NotetypeLayout.guess(fields: Self.hskFields)).contains("SentenceSimplified"))
        XCTAssertTrue(NotetypeLayout.front(mapping).contains("SentenceSimplified"), "example on the front when asked")
    }

    func testCSSHasNoBackgroundAndKeepsOldCSS() {
        let css = NotetypeLayout.css(original: ImportedFixtures.lightCSS)
        XCTAssertEqual(CardStyle.decide(css: css), .ink)
        XCTAssertTrue(css.contains(".nightMode .cl-hanzi"))
        XCTAssertEqual(NotetypeStyle.restored(from: css), ImportedFixtures.lightCSS)
        XCTAssertEqual(NotetypeLayout.css(original: css), css, "generating twice is stable")
    }

    func testTemplateCommentRoundTripsTrickyText() {
        let old = "{{#A}}x{{/A}} <!-- c --> {{FrontSide}}"
        let wrapped = NotetypeLayout.wrap("new", original: old, marker: NotetypeLayout.backMarker)
        XCTAssertFalse(wrapped.dropFirst(3).contains("{{"), "the kept copy is not parsed as fields")
        XCTAssertEqual(NotetypeLayout.previous(in: wrapped, marker: NotetypeLayout.backMarker), old)
    }
}

final class NotetypeLayoutEngineTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws { directory = try makeTempDirectory() }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: directory) }

    func testApplyKeepsFieldsAndNotesAndRestoreGivesBackTheOldTemplates() async throws {
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let deck = try await backend.addDeck(name: "Fixture")
        let stock = try await backend.stockNotetypeJSON(kind: .basic)
        let ntid = try await backend.addNotetype(
            json: try ImportedFixtures.json(basedOn: stock, name: "HSK+ shape", css: ImportedFixtures.lightCSS))
        let fields = ImportedFixtures.fieldValues(ImportedFixtures.lightNote, withMedia: false)
        let noteID = try await backend.addNote(notetypeID: ntid, deckID: deck, fields: fields)

        let original = try await backend.getNotetype(id: ntid)
        let mapping = NotetypeLayout.guess(
            fields: original.fields.map(\.name), frontTemplate: NotetypeLayout.originalFront(original))
        XCTAssertEqual(mapping[.hanzi], "Simplified")

        try await backend.updateNotetype(NotetypeLayout.applying(mapping, to: original))
        let converted = try await backend.getNotetype(id: ntid)
        XCTAssertEqual(converted.fields.map(\.name), original.fields.map(\.name), "field list unchanged")
        XCTAssertTrue(converted.templates[0].config.aFormat.contains("cl-meaning"))
        XCTAssertTrue(NotetypeLayout.canRestore(converted))
        let note = try await backend.getNote(id: noteID)
        XCTAssertEqual(note.fields, fields, "note content unchanged")

        // Converting again starts from the original, so nothing nests.
        try await backend.updateNotetype(NotetypeLayout.applying(mapping, to: converted))
        let again = try await backend.getNotetype(id: ntid)
        XCTAssertEqual(again.templates[0].config.aFormat, converted.templates[0].config.aFormat)

        let restored = try XCTUnwrap(NotetypeLayout.restoring(again))
        try await backend.updateNotetype(restored)
        let back = try await backend.getNotetype(id: ntid)
        XCTAssertEqual(back.templates[0].config.qFormat, original.templates[0].config.qFormat)
        XCTAssertEqual(back.templates[0].config.aFormat, original.templates[0].config.aFormat)
        XCTAssertEqual(back.config.css, original.config.css)

        try await backend.updateNotetype(NotetypeLayout.applying(mapping, to: back))
        try await backend.undo()
        let undone = try await backend.getNotetype(id: ntid)
        XCTAssertEqual(undone.templates[0].config.aFormat, original.templates[0].config.aFormat, "engine undo works")
        try await backend.closeCollection()
    }
}
