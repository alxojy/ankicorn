import Foundation

/// Launch arguments that change how the app starts (used by tests and previews).
struct LaunchOptions: Equatable {
    /// Create the sample decks through the engine if they are missing.
    var seedSample = false
    /// Delete the collection files before opening, so every launch starts empty.
    var resetCollection = false
    /// Show the full-sync prompt on launch, for screenshots and UI tests (no account or network involved).
    var showFullSyncChoice = false

    init(seedSample: Bool = false, resetCollection: Bool = false, showFullSyncChoice: Bool = false) {
        self.seedSample = seedSample
        self.resetCollection = resetCollection
        self.showFullSyncChoice = showFullSyncChoice
    }

    init(arguments: [String]) {
        seedSample = arguments.contains("--seed-sample")
        resetCollection = arguments.contains("--reset-collection")
        showFullSyncChoice = arguments.contains("--show-full-sync-choice")
    }
}
