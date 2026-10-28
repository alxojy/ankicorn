import XCTest

@testable import Cornhub

final class SpeechTargetTests: XCTestCase {
    func testChineseVocabSpeaksHanziOnly() {
        let target = SpeechTarget.pick(
            names: ["Hanzi", "Pinyin", "English", "Audio"], fields: ["你好", "nǐ hǎo", "hello", ""],
            question: "你好", language: "zh-CN")
        XCTAssertEqual(target, .text("你好"))
    }

    func testAudioFieldWins() {
        let target = SpeechTarget.pick(
            names: ["Hanzi", "Audio"], fields: ["你好", "[sound:x.mp3]"], question: "你好", language: "zh-CN")
        XCTAssertEqual(target, .audio("x.mp3", fallback: "你好"))
    }

    func testBasicNoteStripsHTML() {
        let target = SpeechTarget.pick(
            names: ["Front", "Back"], fields: ["<b>bonjour</b>&nbsp;<br>", "hello"], question: "bonjour", language: "fr-FR")
        XCTAssertEqual(target, .text("bonjour"))
    }

    func testSharedDeckFieldsGiveTheHeadwordAndFallBackToItWhenSoundIsMissing() {
        let fields = ImportedFixtures.fieldValues(ImportedFixtures.lightNote, withMedia: true)
        let target = SpeechTarget.pick(names: ImportedFixtures.fields, fields: fields, question: "月亮", language: "zh-CN")
        XCTAssertEqual(target, .audio("fx-moon.mp3", fallback: "月亮"))
        XCTAssertFalse(MediaSchemeHandler.exists("definitely-not-there.mp3"), "a missing file is detected, so Speak uses TTS")
    }

    func testHeadwordIsFirstMostlyHanziFieldOnUnnamedNoteTypes() {
        let word = SpeechTarget.headword(
            names: ["Key", "Notes", "Term"], fields: ["id-7", "see [sound:a.mp3] below", "{{c1::学习::study}}好"],
            question: "", language: "zh-CN")
        XCTAssertEqual(word, "学习好")
    }

    func testHeadwordFallsBackToFirstFieldThenQuestion() {
        XCTAssertEqual(
            SpeechTarget.headword(names: ["A", "B"], fields: ["", "<i>hello</i>"], question: "q", language: "en-US"), "hello")
        XCTAssertEqual(SpeechTarget.headword(names: ["A"], fields: [""], question: "<b>q</b>", language: "en-US"), "q")
    }
}
