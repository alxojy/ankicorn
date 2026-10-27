import Foundation

/// What to study: one deck (and its subdecks), or whatever the engine's current deck is.
struct ReviewTarget: Identifiable {
    let deckID: Int64?
    var id: Int64 { deckID ?? 0 }
}
