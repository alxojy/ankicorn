import Foundation
import Observation
import Translation

/// The answer-side extras for the shown card: speech, translation, explanation and stroke order.
@MainActor
@Observable
final class ExtrasModel {
    enum Panel: Equatable {
        case none
        case explanation(String)
        case translation(String)
        case strokes([Character])
        case message(String)
        case loading(String)
    }

    private(set) var panel = Panel.none
    var translationConfig: TranslationSession.Configuration?
    private(set) var translationText = ""
    private let speaker = Speaker()
    private let cache = ExplanationCache()
    private var task: Task<Void, Never>?

    var noteID: Int64 = 0
    var deckID: Int64 = 0
    var questionText = ""
    var answerText = ""

    var allText: String { [questionText, answerText].filter { !$0.isEmpty }.joined(separator: "\n") }
    var hanzi: [Character] { CardText.hanzi(allText) }
    var language: String { SpeechSettings.language(deckID: deckID) }

    func reset() {
        task?.cancel()
        speaker.stop()
        panel = .none
        translationConfig = nil
        explainInput = nil
    }

    /// Set per card by the review screen; Speak says only this (the note's audio, else the headword).
    var speech = SpeechTarget.text("")
    var playFile: ((String) -> Void)?

    func speak() {
        switch speech {
        case .audio(let file, let fallback):
            if MediaSchemeHandler.exists(file) { playFile?(file) } else { speaker.speak(fallback, language: language) }
        case .text(let word): speaker.speak(word, language: language)
        }
    }

    func showStrokes() {
        let chars = hanzi
        panel = chars.isEmpty ? .message("No hanzi on this card.") : .strokes(chars)
    }

    /// The headword, pinyin, meaning and sentence of the shown note; set by the review screen once the note loads.
    var explainInput: ExplainInput?
    var generator: TextGenerating = SystemTextGenerator()

    func explain() {
        let input = explainInput ?? ExplainInput(headword: questionText, pinyin: "", meaning: answerText, sentence: "")
        let key = ExplanationCache.key(noteID: noteID, text: input.prompt)
        if let cached = cache.value(for: key) {
            panel = .explanation(cached)
            return
        }
        panel = .loading("Explaining…")
        task?.cancel()
        task = Task {
            let outcome = await ExplainRunner.run(input, generator: generator)
            guard !Task.isCancelled else { return }
            switch outcome {
            case .text(let text):
                cache.store(text, for: key)
                panel = .explanation(text)
            case .message(let text): panel = .message(text)
            }
        }
    }

    /// Source language from the card text, target the device language; same language short-circuits.
    func translate() {
        let source = TranslateLanguages.detect(allText, fallback: language)
        let target = Locale.current.language
        if TranslateLanguages.isSame(source, target) {
            panel = .message(TranslateLanguages.alreadyMessage(target: target))
            return
        }
        translationText = allText
        translationSource = source
        panel = .loading("Translating…")
        translationConfig = .init(source: source, target: target)
    }

    private var translationSource = Locale.Language(identifier: "zh-Hans")

    var textToTranslate: String { translationText }

    func finishTranslation(_ text: String?) {
        panel = text.map { .translation($0) } ?? .message(TranslateLanguages.unavailableMessage(source: translationSource))
    }
}
