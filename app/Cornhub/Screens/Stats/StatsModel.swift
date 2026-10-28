import Foundation
import Observation

enum StatsRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var id: String { rawValue }

    /// Days the range covers; also the length of the activity window.
    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .year: 364
        }
    }

    /// "7 days", "30 days", "12 months": how the range reads in labels.
    var phrase: String {
        switch self {
        case .week: "7 days"
        case .month: "30 days"
        case .year: "12 months"
        }
    }

    /// Forecast buckets: daily for week and month, 30-day buckets (about months) for year.
    var forecastBuckets: Int { self == .year ? 12 : days }
    var forecastBucketDays: Int { self == .year ? 30 : 1 }
}

struct StatsDeck: Identifiable, Hashable {
    let id: Int64
    let name: String

    /// The deck's own name: the last `::` component of the full path.
    var leafName: String { name.components(separatedBy: "::").last ?? name }
    /// The path above the deck ("A::B" for "A::B::C"), or nil for a top-level deck.
    var parentPath: String? {
        let parts = name.components(separatedBy: "::")
        return parts.count > 1 ? parts.dropLast().joined(separator: " › ") : nil
    }
    /// How many parents the deck has; the picker indents by this.
    var depth: Int { name.components(separatedBy: "::").count - 1 }
}

/// Reads the engine's `graphs` response and reduces it to what the Stats tab shows. No statistics are computed
/// here beyond summing the engine's own counts.
@MainActor @Observable
final class StatsModel {
    enum Phase { case loading, empty, failed(String), ready }

    let backend: Backend
    private(set) var phase = Phase.loading
    private(set) var decks: [StatsDeck] = []
    var deck: StatsDeck? { didSet { Task { await load() } } }
    var range = StatsRange.week

    private var response: Anki_Stats_GraphsResponse?

    init(backend: Backend) {
        self.backend = backend
    }

    private var retentionBucket: Anki_Stats_GraphsResponse.TrueRetentionStats.TrueRetention? {
        guard let response else { return nil }
        let stats = response.trueRetention
        return switch range {
        case .week: stats.week
        case .month: stats.month
        case .year: stats.year
        }
    }

    /// Answers the retention figure is based on (passed + failed) in the selected range.
    var retentionReviews: Int {
        guard let value = retentionBucket else { return 0 }
        return Int(value.youngPassed + value.maturePassed + value.youngFailed + value.matureFailed)
    }

    /// True retention for the selected range as a 0...1 fraction, or nil when nothing was answered.
    var retention: Double? {
        guard let value = retentionBucket, retentionReviews > 0 else { return nil }
        return Double(value.youngPassed + value.maturePassed) / Double(retentionReviews)
    }

    /// Reviews per day for the selected range, oldest first (last is today).
    var activity: [Int] {
        StudyStreak.dailyCounts(response?.reviews.count ?? [:], days: range.days)
    }

    /// A year of reviews per day; the streak looks back through it.
    private var streakWindow: [Int] {
        StudyStreak.dailyCounts(response?.reviews.count ?? [:], days: 365)
    }

    /// Cards due per forecast bucket for the selected range (daily, or 30-day buckets for the year).
    var forecast: [Int] {
        let due = response?.futureDue.futureDue ?? [:]
        let size = range.forecastBucketDays
        return (0..<range.forecastBuckets).map { bucket in
            (0..<size).reduce(0) { $0 + Int(due[Int32(bucket * size + $1)] ?? 0) }
        }
    }

    /// Reviews, minutes and days studied across the selected range.
    var totals: (reviews: Int, minutes: Int, daysStudied: Int) {
        let counts = activity
        let millis = StudyStreak.dailyCounts(response?.reviews.time ?? [:], days: range.days)
        return (counts.reduce(0, +), Int((Double(millis.reduce(0, +)) / 60000).rounded()), counts.filter { $0 > 0 }.count)
    }

    /// Consecutive days with reviews, counting back from today (or yesterday if today has none yet).
    var streak: Int {
        StudyStreak.days(streakWindow)
    }

    /// Uses a response directly; `load()` does this after the engine call.
    func apply(_ result: Anki_Stats_GraphsResponse) {
        response = result
        let hasReviews = result.reviews.count.values.contains { $0.learn + $0.relearn + $0.young + $0.mature + $0.filtered > 0 }
        phase = hasReviews || !result.futureDue.futureDue.isEmpty ? .ready : .empty
    }

    func load() async {
        if decks.isEmpty, let tree = try? await backend.deckTree() {
            decks = Self.flatten(tree.children)
        }
        do {
            let search = deck.map { "deck:\"\($0.name)\"" } ?? ""
            let result = try await backend.graphs(search: search, days: 365)
            apply(result)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private static func flatten(_ nodes: [Anki_Decks_DeckTreeNode], prefix: String = "") -> [StatsDeck] {
        nodes.flatMap { node in
            let full = prefix.isEmpty ? node.name : "\(prefix)::\(node.name)"
            return [StatsDeck(id: node.deckID, name: full)] + flatten(node.children, prefix: full)
        }
    }
}

/// The study streak, shared by the Stats tab and the Decks home so both show the same engine-backed value.
enum StudyStreak {
    /// Reviews per day from the engine's `graphs` review counts (keyed by day offset, 0 = today), oldest first.
    static func dailyCounts(_ counts: [Int32: Anki_Stats_GraphsResponse.ReviewCountsAndTimes.Reviews], days: Int) -> [Int] {
        (-(days - 1)...0).map { offset in
            guard let day = counts[Int32(offset)] else { return 0 }
            return Int(day.learn + day.relearn + day.young + day.mature + day.filtered)
        }
    }

    /// Consecutive days with reviews, counting back from the last entry (today), or from yesterday when
    /// today has none yet. `counts` is oldest first.
    static func days(_ counts: [Int]) -> Int {
        guard var index = counts.indices.last else { return 0 }
        if counts[index] == 0 { index -= 1 }
        var days = 0
        while index >= 0, counts[index] > 0 {
            days += 1
            index -= 1
        }
        return days
    }
}
