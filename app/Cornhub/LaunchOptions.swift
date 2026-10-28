import Foundation

/// Launch arguments that change how the app starts (used by tests and previews).
struct LaunchOptions: Equatable {
    /// Create the sample decks through the engine if they are missing.
    var seedSample = false
    /// Delete the collection files before opening, so every launch starts empty.
    var resetCollection = false
    /// Show the full-sync prompt on launch, for screenshots and UI tests (no account or network involved).
    var showFullSyncChoice = false

    /// Log in without the network (any credentials succeed), starting signed out. Tests only.
    var stubLogin = false
    /// Create the sample decks with exactly one due card in the first one. Tests only.
    var seedOneDue = false
    /// Create the sample decks with no cards at all, so review opens straight to "All done for now". Tests only.
    var seedNoDue = false

    init(
        seedSample: Bool = false, resetCollection: Bool = false, showFullSyncChoice: Bool = false, stubLogin: Bool = false,
        seedOneDue: Bool = false, seedNoDue: Bool = false
    ) {
        self.seedOneDue = seedOneDue
        self.seedNoDue = seedNoDue
        self.stubLogin = stubLogin
        self.seedSample = seedSample
        self.resetCollection = resetCollection
        self.showFullSyncChoice = showFullSyncChoice
    }

    init(arguments: [String]) {
        seedSample = arguments.contains("--seed-sample")
        resetCollection = arguments.contains("--reset-collection")
        showFullSyncChoice = arguments.contains("--show-full-sync-choice")
        stubLogin = arguments.contains("--stub-login")
        seedOneDue = arguments.contains("--seed-one-due")
        seedNoDue = arguments.contains("--seed-no-due")
    }
}
