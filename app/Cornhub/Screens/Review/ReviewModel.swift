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

    private let backend: Backend
    private let deckID: Int64?
    private var queued: Anki_Scheduler_QueuedCards.QueuedCard?
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

    var answerHTML: String { rendered?.answer ?? "" }
    var questionHTML: String { rendered?.question ?? "" }

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
    }

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

    private func loadNext() async throws {
        let result = try await backend.getQueuedCards()
        counts = Counts(new: Int(result.newCount), learning: Int(result.learningCount), review: Int(result.reviewCount))
        let status = try await backend.undoStatus()
        undoLabel = status.undo
        redoLabel = status.redo
        revealed = false
        guard let next = result.cards.first else {
            queued = nil
            rendered = nil
            congrats = try await backend.congratsInfo()
            phase = .congrats
            return
        }
        queued = next
        rendered = try await backend.renderExistingCard(id: next.card.id)
        let labels = try await backend.describeNextStates(next.states)
        intervals = labels.count == 4 ? labels : ["", "", "", ""]
        shownAt = Date()
        phase = .card
    }
}
