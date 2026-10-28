import Foundation
import Observation

/// Card counts for one deck (with its subdecks), all from engine searches.
struct DeckCardCounts: Equatable {
    var total = 0
    /// `prop:ivl>=21`, Anki's own definition of mature.
    var mature = 0
    /// Seen but not mature.
    var young = 0
    /// `is:new`: never seen.
    var unseen = 0

    var seen: Int { max(total - unseen, 0) }
}

/// What the deck screen shows beyond the deck tree: collection counts, limits, last review and the forecast.
@MainActor @Observable
final class DeckOverviewModel {
    private(set) var counts = DeckCardCounts()
    private(set) var levelCounts: [Int64: DeckCardCounts] = [:]
    private(set) var description = ""
    /// Days since the last review in this deck, nil when it was never studied.
    private(set) var lastStudiedDays: Int?
    /// Cards due on each of the next 7 days, tomorrow first.
    private(set) var forecast: [Int] = []
    /// New cards the deck could show today without the daily limit.
    private(set) var newAvailable = 0
    /// Review cards due today without the daily limit.
    private(set) var reviewAvailable = 0
    private(set) var loaded = false

    func load(deck: DeckTile, backend: Backend) async {
        let name = Self.fullName(deck)
        let search = Self.deckSearch(name)
        counts = await Self.counts(search, backend)
        var perLevel: [Int64: DeckCardCounts] = [:]
        for child in deck.children { perLevel[child.id] = await Self.counts(Self.deckSearch(Self.fullName(child)), backend) }
        levelCounts = perLevel
        newAvailable = await Self.count("\(search) is:new -is:suspended -is:buried", backend)
        reviewAvailable = await Self.count("\(search) is:review is:due -is:suspended -is:buried", backend)
        if let found = try? await backend.getDeck(id: deck.id) { description = found.normal.description_p }
        if let graphs = try? await backend.graphs(search: search, days: 365) {
            lastStudiedDays = Self.lastStudiedDays(graphs.reviews.count)
            forecast = Self.forecast(graphs.futureDue.futureDue)
        }
        loaded = true
    }

    // MARK: Pure helpers (unit tested)

    static func fullName(_ deck: DeckTile) -> String { deck.fullName.isEmpty ? deck.name : deck.fullName }

    /// `"deck:Name"` for the engine's search, quoted and with wildcards and quotes escaped. Includes subdecks.
    static func deckSearch(_ fullName: String) -> String {
        let escaped = fullName
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "*", with: "\\*")
            .replacingOccurrences(of: "_", with: "\\_")
        return "\"deck:\(escaped)\""
    }

    static func counts(_ deckSearch: String, _ backend: Backend) async -> DeckCardCounts {
        let total = await count(deckSearch, backend)
        let unseen = await count("\(deckSearch) is:new", backend)
        let mature = await count("\(deckSearch) prop:ivl>=21", backend)
        return DeckCardCounts(total: total, mature: mature, young: max(total - unseen - mature, 0), unseen: unseen)
    }

    static func count(_ search: String, _ backend: Backend) async -> Int {
        (try? await backend.browserSearch(search, notes: false).count) ?? 0
    }

    /// The Study button number: what the engine says is due today (limits applied).
    static func studyTotal(_ deck: DeckTile) -> Int { deck.newCount + deck.learningCount + deck.reviewCount }

    /// True when a daily limit holds back cards: more are available than the engine shows for today.
    static func isCapped(available: Int, shown: Int) -> Bool { available > shown }

    /// Second line under a capped tile.
    static func cappedLine(available: Int, shown: Int) -> String {
        shown == 0 ? "limit reached" : "of \(available) · capped"
    }

    /// Only decks with subdecks get a Levels list.
    static func showsLevels(_ deck: DeckTile) -> Bool { !deck.children.isEmpty }

    /// Days since the newest day with reviews in the engine's review counts (key 0 = today, negative = past).
    static func lastStudiedDays(_ reviews: [Int32: Anki_Stats_GraphsResponse.ReviewCountsAndTimes.Reviews]) -> Int? {
        let studied = reviews.filter { $0.value.learn + $0.value.relearn + $0.value.young + $0.value.mature + $0.value.filtered > 0 }
        return studied.keys.max().map { Int(-$0) }
    }

    static func lastStudiedText(_ days: Int?) -> String {
        guard let days else { return "Not studied yet" }
        switch days {
        case 0: return "Last studied today"
        case 1: return "Last studied yesterday"
        default: return "Last studied \(days) days ago"
        }
    }

    /// The engine's future due counts (key 0 = today) for the next 7 days, tomorrow first.
    static func forecast(_ due: [Int32: UInt32]) -> [Int] { (1...7).map { Int(due[Int32($0)] ?? 0) } }

    /// "1,201 cards · 4 levels", shown under the name of a top-level deck.
    static func subtitle(_ deck: DeckTile) -> String {
        let cards = "\(deck.totalCards.formatted()) \(deck.totalCards == 1 ? "card" : "cards")"
        guard !deck.children.isEmpty else { return cards }
        return "\(cards) · \(deck.children.count) \(deck.children.count == 1 ? "level" : "levels")"
    }

    /// "Mandarin (HSK) ›" path above a subdeck's name, or nil for a top-level deck.
    static func breadcrumb(_ deck: DeckTile) -> String? {
        let parts = fullName(deck).components(separatedBy: "::")
        guard parts.count > 1 else { return nil }
        return parts.dropLast().joined(separator: " › ") + " ›"
    }

    /// The full name of the deck's parent, or nil for a top-level deck.
    static func parentName(_ deck: DeckTile) -> String? {
        let parts = fullName(deck).components(separatedBy: "::")
        return parts.count > 1 ? parts.dropLast().joined(separator: "::") : nil
    }
}
