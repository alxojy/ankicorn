## Why
The user reports that on the "All done for now" screen, the buttons at the top right (Undo and ⋯) don't work.

Cause, found by reading `ReviewScreen.header` (the worker must confirm it):
- The header is the same in every phase. On congrats, Undo is `.disabled(model.undoLabel.isEmpty)`, which is disabled whenever nothing was graded in this session (for example Start review with nothing left, or reopening review). But the HStack sets `.foregroundStyle(Theme.text)`, so a disabled button looks exactly like an active one.
- The ⋯ menu shows the card actions only when `phase == .card`. On congrats it holds just "Redo", which is usually disabled. Tapping ⋯ opens a menu with one greyed-out item, or what seems like nothing.
- Also check: after grading the last card, does Undo from congrats really bring that card back? `undo()` calls `loadNext()`. In all-decks mode (`deckID == nil`), `moveToNextDueDeck` may have changed the current deck, so the restored card might not be found and congrats would show again.

## What Changes
- **Congrats header:** show the close button. Show Undo only when there's something to undo (`undoLabel` not empty). Show ⋯ only when it has an enabled action; on congrats it's hidden. No dead controls.
- **Undo from congrats works:** after grading the last card, Undo puts that card back on screen, on the question side, with the counts updated. In all-decks mode, select the restored card's deck first (the engine's undo result or the card's `deck_id`).
- **Disabled controls look disabled** throughout the review header: they use the `zero`/muted token, not `text`. Remove the blanket foreground override for disabled states.
- The congrats screen can also offer "Undo last answer" as a secondary text button under "Back to decks", when undo is available. This is optional; skip it if it clutters the screen.

## Impact
`app/Cornhub/Screens/Review/ReviewScreen.swift`, `ReviewModel.swift`, maybe `CongratsScreen.swift`, and `ScreenTourUITests`.
