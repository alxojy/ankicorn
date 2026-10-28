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
        XCTAssertEqual(target, .audio("x.mp3"))
    }

    func testBasicNoteStripsHTML() {
        let target = SpeechTarget.pick(
            names: ["Front", "Back"], fields: ["<b>bonjour</b>&nbsp;<br>", "hello"], question: "bonjour", language: "fr-FR")
        XCTAssertEqual(target, .text("bonjour"))
    }
}
