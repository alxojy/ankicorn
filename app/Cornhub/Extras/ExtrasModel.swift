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
    }

    func speak() { speaker.speak(answerText.isEmpty ? questionText : answerText, language: language) }

    func showStrokes() {
        let chars = hanzi
        panel = chars.isEmpty ? .message("No hanzi on this card.") : .strokes(chars)
    }

    func explain() {
        let key = ExplanationCache.key(noteID: noteID, text: allText)
        if let cached = cache.value(for: key) {
            panel = .explanation(cached)
            return
        }
        panel = .loading("Explaining…")
        task?.cancel()
        task = Task {
            do {
                let text = try await TextGenerator.generate(
                    instructions: "You explain flashcards to a language learner. Be concise: meaning, grammar or usage, "
                        + "one memory aid. Plain text, under 120 words.",
                    prompt: "Explain this flashcard:\n\(allText)")
                guard !Task.isCancelled else { return }
                cache.store(text, for: key)
                panel = .explanation(text)
            } catch {
                guard !Task.isCancelled else { return }
                panel = .message(error.localizedDescription)
            }
        }
    }

    func translate() {
        let source = Locale.Language(identifier: String(language.prefix(2)) == "zh" ? "zh-Hans" : String(language.prefix(2)))
        translationText = allText
        panel = .loading("Translating…")
        translationConfig = .init(source: source, target: Locale.Language(identifier: "en"))
    }

    var textToTranslate: String { translationText }

    func finishTranslation(_ text: String?) {
        panel = text.map { .translation($0) } ?? .message("Translation is not available for this language on this device.")
    }
}
