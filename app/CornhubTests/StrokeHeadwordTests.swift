import XCTest

@testable import Cornhub

@MainActor
final class StrokeHeadwordTests: XCTestCase {
    private func model(headword: String, sentence: String) -> ExtrasModel {
        let model = ExtrasModel()
        model.questionText = headword
        model.answerText = sentence
        model.headword = headword
        return model
    }

    func testImportedFixtureGivesOnlyTheHeadwordCharacters() {
        let fields = ImportedFixtures.fieldValues(ImportedFixtures.lightNote, withMedia: true)
        let word = SpeechTarget.headword(names: ImportedFixtures.fields, fields: fields, question: "月亮", language: "zh-CN")
        let extras = model(headword: word, sentence: "今晚的月亮很圆。")
        XCTAssertEqual(extras.hanzi, ["月", "亮"])
        extras.showStrokes()
        XCTAssertEqual(extras.panel, .strokes(["月", "亮"]))
    }

    func testSentenceHanziAreIgnored() {
        let extras = model(headword: "怎么样", sentence: "这件衣服怎么样？")
        XCTAssertEqual(extras.hanzi, ["怎", "么", "样"])
    }

    func testRepeatedCharactersAppearOnce() {
        XCTAssertEqual(model(headword: "妈妈", sentence: "").hanzi, ["妈"])
    }

    func testNoHanziHidesTheButtonAndShowsNothing() {
        let extras = model(headword: "hello", sentence: "你好")
        XCTAssertTrue(extras.hanzi.isEmpty)
        extras.showStrokes()
        XCTAssertEqual(extras.panel, .none)
    }
}
