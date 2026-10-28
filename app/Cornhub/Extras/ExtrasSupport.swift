import Foundation
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

/// What Explain sends the model: the headword, its pinyin, the meaning and one example sentence.
struct ExplainInput: Equatable {
    var headword: String
    var pinyin: String
    var meaning: String
    var sentence: String

    /// Picks the parts out of the note's fields by name, falling back to the headword logic and `Pinyin`.
    /// Everything is cleaned of HTML, sound tags and brackets, and repeats of the headword are dropped.
    static func from(names: [String], fields: [String], question: String, language: String) -> ExplainInput {
        let word = SpeechTarget.headword(names: names, fields: fields, question: question, language: language)
        func value(_ match: (String) -> Bool) -> String {
            guard let index = names.indices.first(where: { match(names[$0].lowercased()) && fields.indices.contains($0) })
            else { return "" }
            return SpeechTarget.clean(fields[index])
        }
        var pinyin = value { $0.hasPrefix("pinyin") }
        if pinyin.isEmpty { pinyin = Pinyin.from(word) }
        let meaning = value { name in
            !name.contains("sentence") && ["meaning", "english", "definition", "translation"].contains { name.contains($0) }
        }
        let sentence = value { $0.hasPrefix("sentence") && !$0.contains("pinyin") && !$0.contains("meaning") && !$0.contains("audio") && !$0.contains("image") }
        return ExplainInput(headword: word, pinyin: pinyin, meaning: meaning, sentence: sentence)
    }

    /// Distinct, non-empty lines; "word (pinyin)" style repeats collapse.
    private var lines: [(String, String)] {
        var seen = Set<String>()
        return [("Word", headword), ("Pinyin", pinyin), ("Meaning", meaning), ("Example", sentence)]
            .filter { !$0.1.isEmpty && seen.insert($0.1).inserted }
    }

    /// The compact prompt in the device language; the Chinese is quoted as the material.
    var prompt: String {
        "Explain this word for a language learner:\n" + lines.map { "\($0.0): \"\($0.1)\"" }.joined(separator: "\n")
    }

    /// Pinyin and English only, with the number of hanzi stated, for a model that rejects Chinese text.
    var romanisedPrompt: String {
        let count = CardText.hanzi(headword + sentence).count
        let parts = [("Pinyin", pinyin), ("Meaning", meaning)].filter { !$0.1.isEmpty }
        return "Explain this Mandarin word for a language learner (it is written with \(count) Chinese characters, "
            + "not shown):\n" + parts.map { "\($0.0): \"\($0.1)\"" }.joined(separator: "\n")
    }

    static func instructions(localeIdentifier: String, languageName: String) -> String {
        "The person's locale is \(localeIdentifier). Respond in \(languageName). You explain flashcards to a language "
            + "learner. Be concise: meaning, grammar or usage, one memory aid. Plain text, under 120 words."
    }
}

/// A text generator the extras can be tested against.
protocol TextGenerating: Sendable {
    /// Whether the generator can answer in the device locale.
    var supportsDeviceLocale: Bool { get }
    func generate(instructions: String, prompt: String) async throws -> String
    func isUnsupportedLanguage(_ error: Error) -> Bool
}

struct SystemTextGenerator: TextGenerating {
    var supportsDeviceLocale: Bool {
        #if canImport(FoundationModels)
        if TextGenerator.onDeviceAvailable { return SystemLanguageModel.default.supportsLocale(Locale.current) || ClaudeKeychain.load() != nil }
        #endif
        return true
    }

    func generate(instructions: String, prompt: String) async throws -> String {
        try await TextGenerator.generate(instructions: instructions, prompt: prompt)
    }

    func isUnsupportedLanguage(_ error: Error) -> Bool { TextGenerator.isUnsupportedLanguage(error) }
}

enum ExplainRunner {
    static let unavailableMessage = "Explain isn't available in this language on this device."

    enum Outcome: Equatable {
        case text(String)
        case message(String)
    }

    /// Explains once; on an unsupported-language error retries once with the romanised prompt, then gives the
    /// friendly line. Other errors keep their own description.
    static func run(
        _ input: ExplainInput, generator: TextGenerating, locale: Locale = .current
    ) async -> Outcome {
        guard generator.supportsDeviceLocale else { return .message(unavailableMessage) }
        let identifier = locale.identifier
        let name = locale.language.languageCode.flatMap { locale.localizedString(forLanguageCode: $0.identifier) } ?? "English"
        let instructions = ExplainInput.instructions(localeIdentifier: identifier, languageName: name)
        do {
            return .text(try await generator.generate(instructions: instructions, prompt: input.prompt))
        } catch where generator.isUnsupportedLanguage(error) {
            do {
                return .text(try await generator.generate(instructions: instructions, prompt: input.romanisedPrompt))
            } catch where generator.isUnsupportedLanguage(error) {
                return .message(unavailableMessage)
            } catch {
                return .message(error.localizedDescription)
            }
        } catch {
            return .message(error.localizedDescription)
        }
    }
}

/// Picking Translate's languages from the card text.
enum TranslateLanguages {
    /// Hanzi give `zh-Hans`; otherwise `NLLanguageRecognizer`; the deck's speech language is the fallback.
    static func detect(_ text: String, fallback: String) -> Locale.Language {
        let letters = text.filter { $0.isLetter }
        if !letters.isEmpty, letters.filter({ SpeechTarget.isHanzi($0) }).count * 5 >= letters.count {
            return Locale.Language(identifier: "zh-Hans")
        }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        if let language = recognizer.dominantLanguage, language != .undetermined {
            return language == .simplifiedChinese || language == .traditionalChinese
                ? Locale.Language(identifier: "zh-Hans") : Locale.Language(identifier: language.rawValue)
        }
        let code = String(fallback.prefix(2))
        return Locale.Language(identifier: code == "zh" ? "zh-Hans" : code)
    }

    static func isSame(_ source: Locale.Language, _ target: Locale.Language) -> Bool {
        source.languageCode == target.languageCode
    }

    static func name(of language: Locale.Language, in locale: Locale = .current) -> String {
        language.languageCode.flatMap { locale.localizedString(forLanguageCode: $0.identifier) } ?? "this language"
    }

    static func alreadyMessage(target: Locale.Language) -> String { "Already in \(name(of: target))." }

    static func unavailableMessage(source: Locale.Language) -> String {
        "Translation for \(name(of: source)) isn't available on this device. Download it in Settings › Apps › Translate."
    }
}
