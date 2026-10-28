import XCTest

@testable import Cornhub

final class PinyinTests: XCTestCase {
    func testPinyinFromHanzi() {
        XCTAssertEqual(Pinyin.from("你好"), "nǐ hǎo")
        XCTAssertEqual(Pinyin.from("学生"), "xué shēng")
    }

    func testMarkupIsStripped() {
        XCTAssertEqual(Pinyin.from("<b>你好</b>&nbsp;"), "nǐ hǎo")
    }

    func testNoHanziGivesEmpty() {
        XCTAssertEqual(Pinyin.from("hello"), "")
    }

    @MainActor func testAutoFillRules() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let backend = try Backend()
        try await backend.openCollection(path: directory.appending(path: "collection.anki2"))
        let id = try await backend.ensureChineseNotetype()
        let model = NoteEditorModel(backend: backend, mode: .add)
        await model.load()
        try await model.selectNotetype(id)
        XCTAssertTrue(model.autoFillsPinyin)
        model.fields[ChineseNotetype.Field.hanzi] = "你好"
        model.applyAutoFill()
        XCTAssertEqual(model.fields[ChineseNotetype.Field.pinyin], "nǐ hǎo")
        model.fields[ChineseNotetype.Field.pinyin] = "my own"
        model.fields[ChineseNotetype.Field.hanzi] = "学生"
        model.applyAutoFill()
        XCTAssertEqual(model.fields[ChineseNotetype.Field.pinyin], "my own", "edited field is never overwritten")
        model.fields[ChineseNotetype.Field.pinyin] = ""
        model.fields[ChineseNotetype.Field.hanzi] = "你"
        model.applyAutoFill()
        model.fields[ChineseNotetype.Field.hanzi] = ""
        model.applyAutoFill()
        XCTAssertEqual(model.fields[ChineseNotetype.Field.pinyin], "", "clearing hanzi clears auto values")
    }
}
