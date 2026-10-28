## Why
User screenshot of Stats with a subdeck selected: the header reads "darin (HSK)::一. HSK1", cut off on the left and right, and the ▾ chevron is off-screen.

Cause, in `StatsScreen.deckPicker`:
- The `Menu` label shows the deck's **full path** (`model.deck?.name`, built in `StatsModel` as `parent::child`).
- It uses the large display font (`.inkAnswer`).
- A `Menu` label isn't width-constrained or truncated, so the text lays out at its natural width, which is wider than the phone. SwiftUI centres the overflow, so both ends get clipped.

The picker list also shows full `A::B` paths.

## What Changes
- **Header shows the leaf name:** the deck's own name ("一. HSK1") in the display style, one line, truncating at the tail with "…". When the deck is a subdeck, its parent path shows above it as a small muted caption ("Mandarin (HSK)"). The chevron stays visible next to the name. The whole label is constrained to the screen width with the standard 16 pt margins.
- **Smaller title size:** the deck title uses the screen-title size (`title2`-like display token), not the card-answer size.
- **Picker list as a tree:** "All decks", then each deck by its leaf name, indented under its parent (or a nested `Menu` per parent), with a ✓ on the current one. No raw `::` anywhere in the UI.
- Audit the other places that show a deck name in a large single-line label: the review header, the deck overview title and the Browse deck chip. Apply the same rule there: leaf name, parent as caption, truncate, never clip.

## Impact
`Screens/Stats/StatsScreen.swift`, `StatsModel.swift` (keep the full name for the search, expose the leaf name and parent path), the audited screens if they share the bug, and tests.
