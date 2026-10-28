import XCTest

@testable import Cornhub

private struct StubGenerator: TextGenerating {
    struct Unsupported: Error {}
    var supportsDeviceLocale = true
    /// Each call pops the next result; the prompts seen are recorded in `log`.
    let results: [Result<String, Error>]
    let log: PromptLog

    final class PromptLog: @unchecked Sendable { var prompts: [String] = [] }

    func generate(instructions: String, prompt: String) async throws -> String {
        log.prompts.append(prompt)
        return try results[min(log.prompts.count, results.count) - 1].get()
    }

    func isUnsupportedLanguage(_ error: Error) -> Bool { error is Unsupported }
}

final class ExtrasLanguageTests: XCTestCase {
    func testDetectsChineseEnglishAndMixed() {
        XCTAssertEqual(TranslateLanguages.detect("今晚的月亮很圆。", fallback: "en-US").languageCode?.identifier, "zh")
        XCTAssertEqual(
            TranslateLanguages.detect("The moon is round tonight and the stars are out.", fallback: "zh-CN").languageCode?.identifier, "en")
        XCTAssertEqual(TranslateLanguages.detect("月亮 yuèliang moon", fallback: "en-US").languageCode?.identifier, "zh")
        XCTAssertEqual(TranslateLanguages.detect("", fallback: "zh-CN").languageCode?.identifier, "zh", "fallback is the deck language")
    }

    func testSameLanguageAndMessages() {
        let english = Locale.Language(identifier: "en"), chinese = Locale.Language(identifier: "zh-Hans")
        XCTAssertTrue(TranslateLanguages.isSame(Locale.Language(identifier: "en-GB"), english))
        XCTAssertFalse(TranslateLanguages.isSame(chinese, english))
        XCTAssertTrue(TranslateLanguages.alreadyMessage(target: english).hasPrefix("Already in "))
        let unavailable = TranslateLanguages.unavailableMessage(source: chinese)
        XCTAssertTrue(unavailable.contains("Settings › Apps › Translate"))
        XCTAssertFalse(unavailable.lowercased().contains("error"))
    }

    func testExplainPromptFromImportedFixtureHasNoDuplicatesOrSoundMarkers() {
        let fields = ImportedFixtures.fieldValues(ImportedFixtures.lightNote, withMedia: true)
        let input = ExplainInput.from(names: ImportedFixtures.fields, fields: fields, question: "月亮", language: "zh-CN")
        XCTAssertEqual(input.headword, "月亮")
        XCTAssertEqual(input.pinyin, "yuèliang")
        XCTAssertEqual(input.meaning, "moon")
        XCTAssertEqual(input.sentence, "今晚的月亮很圆。")
        XCTAssertFalse(input.prompt.contains("sound"))
        XCTAssertFalse(input.prompt.contains("["))
        XCTAssertEqual(input.prompt.components(separatedBy: "\"月亮\"").count - 1, 1, "headword appears once as its own line")
        XCTAssertFalse(input.romanisedPrompt.contains("月"), "the romanised prompt has no hanzi")
        XCTAssertTrue(input.romanisedPrompt.contains("5 Chinese characters") || input.romanisedPrompt.contains("Chinese characters"))
    }

    func testUnsupportedLanguageRetriesOnceRomanisedThenSucceeds() async {
        let log = StubGenerator.PromptLog()
        let generator = StubGenerator(results: [.failure(StubGenerator.Unsupported()), .success("It means moon.")], log: log)
        let input = ExplainInput(headword: "月亮", pinyin: "yuèliang", meaning: "moon", sentence: "")
        let outcome = await ExplainRunner.run(input, generator: generator, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(outcome, .text("It means moon."))
        XCTAssertEqual(log.prompts, [input.prompt, input.romanisedPrompt])
    }

    func testStillUnsupportedGivesFriendlyMessageAfterOneRetry() async {
        let log = StubGenerator.PromptLog()
        let generator = StubGenerator(results: [.failure(StubGenerator.Unsupported())], log: log)
        let input = ExplainInput(headword: "月亮", pinyin: "yuèliang", meaning: "moon", sentence: "")
        let outcome = await ExplainRunner.run(input, generator: generator, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(outcome, .message(ExplainRunner.unavailableMessage))
        XCTAssertEqual(log.prompts.count, 2)
    }

    func testUnsupportedDeviceLocaleSkipsTheModel() async {
        let log = StubGenerator.PromptLog()
        let generator = StubGenerator(supportsDeviceLocale: false, results: [.success("x")], log: log)
        let outcome = await ExplainRunner.run(
            ExplainInput(headword: "a", pinyin: "", meaning: "", sentence: ""), generator: generator)
        XCTAssertEqual(outcome, .message(ExplainRunner.unavailableMessage))
        XCTAssertTrue(log.prompts.isEmpty)
    }
}
