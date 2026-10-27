import Foundation
import Observation

/// One review session: the queue from the engine, the shown card and the answers given.
@MainActor
@Observable
final class ReviewModel {
    enum Phase: Equatable {
        case loading
        case card
        case congrats
        case failed(String)
    }

    struct Counts: Equatable {
        var new = 0
        var learning = 0
        var review = 0
        var total: Int { new + learning + review }
    }

    private(set) var phase = Phase.loading
    private(set) var counts = Counts()
    private(set) var rendered: RenderedCard?
    private(set) var intervals: [String] = ["", "", "", ""]
    private(set) var revealed = false
    private(set) var undoLabel = ""
    private(set) var redoLabel = ""
    private(set) var congrats: Anki_Scheduler_CongratsInfoResponse?
    /// Sounds and TTS for each side, and the typed-answer state, filled by `prepareMedia`.
    private(set) var questionItems: [AVItem] = []
    private(set) var answerItems: [AVItem] = []
    private(set) var questionBody = ""
    private(set) var answerBody = ""
    private(set) var typeExpected: String?
    var typedAnswer = ""
    @ObservationIgnored let audio = CardAudio()

    let backend: Backend
    private let deckID: Int64?
    private(set) var isMarked = false
    fileprivate(set) var queued: Anki_Scheduler_QueuedCards.QueuedCard?
    private var shownAt = Date()
    private var startTotal = 0

    init(backend: Backend, deckID: Int64?) {
        self.backend = backend
        self.deckID = deckID
    }

    /// 0...1 share of the session's starting cards that are done.
    var progress: Double {
        guard startTotal > 0 else { return 0 }
        return max(0, min(1, 1 - Double(counts.total) / Double(startTotal)))
    }

    var answerHTML: String { answerBody }
    var questionHTML: String { questionBody }
    var hasTypeField: Bool { typeExpected != nil }
    var currentItems: [AVItem] { revealed ? answerItems : questionItems }

    func start() async {
        do {
            if let deckID { try await backend.setCurrentDeck(deckID) }
            try await loadNext()
            startTotal = counts.total
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func reveal() {
        guard phase == .card else { return }
        revealed = true
        Task { await prepareAnswer() }
    }

    func replay() { audio.play(currentItems) }

    func answer(_ rating: Anki_Scheduler_CardAnswer.Rating) async {
        guard let queued, revealed else { return }
        let taken = UInt32(max(0, min(60, Date().timeIntervalSince(shownAt))) * 1000)
        do {
            try await backend.answerCard(queued, rating: rating, millisecondsTaken: taken)
            try await loadNext()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func undo() async {
        do {
            try await backend.undo()
            try await loadNext()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func redo() async {
        do {
            try await backend.redo()
            try await loadNext()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Label for the interval under a grade button, e.g. "3d".
    func interval(_ rating: Anki_Scheduler_CardAnswer.Rating) -> String {
        let index = rating.rawValue
        return intervals.indices.contains(index) ? intervals[index] : ""
    }

    fileprivate func loadNext() async throws {
        let result = try await backend.getQueuedCards()
        counts = Counts(new: Int(result.newCount), learning: Int(result.learningCount), review: Int(result.reviewCount))
        let status = try await backend.undoStatus()
        undoLabel = status.undo
        redoLabel = status.redo
        revealed = false
        typedAnswer = ""
        audio.stop()
        guard let next = result.cards.first else {
            queued = nil
            rendered = nil
            congrats = try await backend.congratsInfo()
            phase = .congrats
            return
        }
        queued = next
        isMarked = ((try? await backend.getNote(id: next.card.noteID))?.tags ?? []).contains { $0.lowercased() == "marked" }
        rendered = try await backend.renderExistingCard(id: next.card.id)
        await prepareMedia(note: next.card)
        let labels = try await backend.describeNextStates(next.states)
        intervals = labels.count == 4 ? labels : ["", "", "", ""]
        shownAt = Date()
        phase = .card
    }
}

// MARK: - Card actions

extension ReviewModel {
    var currentFlag: UInt32 { (queued?.card.flags ?? 0) & 7 }

    func setFlag(_ flag: UInt32) async {
        guard let queued else { return }
        let value = currentFlag == flag ? 0 : flag
        await perform(reload: false) {
            try await self.backend.setFlag(cardID: queued.card.id, flag: value)
        }
        refreshQueuedFlag(value)
    }

    func toggleMark() async {
        guard let queued else { return }
        let note = queued.card.noteID
        do {
            let current = try await backend.getNote(id: note)
            let marked = current.tags.contains { $0.lowercased() == "marked" }
            try await backend.setNoteTag(noteID: note, tag: "marked", present: !marked)
            isMarked = !marked
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func bury() async { await removeCard(.buryUser) }
    func suspend() async { await removeCard(.suspend) }

    private func removeCard(_ mode: Anki_Scheduler_BuryOrSuspendCardsRequest.Mode) async {
        guard let queued else { return }
        await perform(reload: true) {
            try await self.backend.buryOrSuspend(cardID: queued.card.id, mode: mode)
        }
    }

    func loadNote() async -> Anki_Notes_Note? {
        guard let queued else { return nil }
        return try? await backend.getNote(id: queued.card.noteID)
    }

    func save(note: Anki_Notes_Note) async {
        await perform(reload: false) { try await self.backend.updateNote(note) }
        if let queued, let fresh = try? await backend.renderExistingCard(id: queued.card.id) {
            rendered = fresh
            await prepareMedia(note: queued.card)
        }
    }

    private func perform(reload: Bool, _ work: () async throws -> Void) async {
        do {
            try await work()
            if reload { try await loadNext() }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

extension ReviewModel {
    fileprivate func refreshQueuedFlag(_ flag: UInt32) {
        queued?.card.flags = (queued?.card.flags ?? 0) & ~7 | flag
    }
}

// MARK: - Media, audio and typed answers

extension ReviewModel {
    private static let typePattern = try! NSRegularExpression(pattern: #"\[\[type:([^\]]+)\]\]"#)

    /// Splits audio out of both sides with the engine and works out the expected typed answer.
    fileprivate func prepareMedia(note card: Anki_Cards_Card) async {
        guard let rendered else { return }
        let question = (try? await backend.extractAvTags(text: rendered.question, question: true))
            ?? (rendered.question, [])
        let answer = (try? await backend.extractAvTags(text: rendered.answer, question: false))
            ?? (rendered.answer, [])
        questionItems = question.1
        answerItems = answer.1
        questionBody = question.0
        answerBody = answer.0
        typeExpected = nil
        if let name = Self.typeFieldName(in: question.0) {
            typeExpected = await expectedAnswer(field: name, card: card)
            questionBody = Self.replaceType(in: question.0, with: "")
        }
        audio.play(questionItems)
    }

    /// Swaps the answer's type placeholder for the engine's diff once the card is revealed.
    fileprivate func prepareAnswer() async {
        if let expected = typeExpected {
            let diff = (try? await backend.compareAnswer(expected: expected, provided: typedAnswer)) ?? ""
            answerBody = Self.replaceType(in: answerBody, with: "<div id=\"typeans\">\(diff)</div>")
        }
        audio.play(answerItems)
    }

    private static func typeFieldName(in html: String) -> String? {
        let range = NSRange(html.startIndex..., in: html)
        guard let match = typePattern.firstMatch(in: html, range: range),
            let found = Range(match.range(at: 1), in: html)
        else { return nil }
        return String(html[found])
    }

    private static func replaceType(in html: String, with replacement: String) -> String {
        let range = NSRange(html.startIndex..., in: html)
        return typePattern.stringByReplacingMatches(
            in: html, range: range, withTemplate: NSRegularExpression.escapedTemplate(for: replacement))
    }

    private func expectedAnswer(field spec: String, card: Anki_Cards_Card) async -> String? {
        let parts = spec.split(separator: ":").map(String.init)
        guard let name = parts.last, let note = try? await backend.getNote(id: card.noteID),
            let names = try? await backend.fieldNames(notetypeID: note.notetypeID),
            let index = names.firstIndex(of: name), note.fields.indices.contains(index)
        else { return nil }
        let value = note.fields[index]
        if parts.contains("cloze") {
            return try? await backend.extractClozeForTyping(text: value, ordinal: card.templateIdx + 1)
        }
        return value.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
