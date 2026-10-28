# decks-home Specification

## Purpose
The Decks home tab: due-count hero, new/learning/review bar, Start review, the deck tile grid and the deck overview, with counts from the engine.

## Requirements

### Requirement: Decks home summary
The Decks tab SHALL show today's date with a sync-status line, round Sync and Add buttons, the total due count in 96 pt display type, a stacked new/learning/review bar with a labelled legend, and a "Start review" button. Counts SHALL come from the engine's `deck_tree`.

#### Scenario: Seeded decks
- **WHEN** the app launches with sample decks
- **THEN** the due total equals the sum of the top-level decks' due counts from `deck_tree`

### Requirement: Deck tile grid
The Decks tab SHALL show the top-level decks as a 2-column grid of tiles with glyph, name, word count, coloured new/learning/review counts (zeros in the zero colour) and a progress bar; each tile SHALL have a VoiceOver label reading the name and counts.

#### Scenario: Open a deck
- **WHEN** the user taps a tile
- **THEN** that deck's overview opens, showing `counts_for_deck_today` and a Study button, and a nested grid when the deck has subdecks

#### Scenario: Collapse
- **WHEN** the user collapses a deck with subdecks
- **THEN** the state is saved with `set_deck_collapsed`

### Requirement: Decks home states
The Decks tab SHALL show designed loading, empty and error states.

#### Scenario: Empty collection
- **WHEN** the collection has no decks besides the default
- **THEN** an empty state invites the user to add a deck

### Requirement: Overview counts match the tile
The deck overview SHALL show the new, learning and review counts of the deck's `deck_tree` node, so they match the home tile.

#### Scenario: Sample deck
- **WHEN** the user opens HSK 1, whose tile shows 45 new
- **THEN** the overview shows 45 new, 0 learning and 0 review

### Requirement: Hero summary line
The hero line under the due count SHALL read "≈ N min · X done today · streak —", where X comes from the engine. The engine's raw sentence SHALL NOT be shown.

#### Scenario: Nothing studied yet
- **WHEN** no cards have been studied today
- **THEN** the line shows "0 done today"

### Requirement: Home matches the Ink mockup
The Decks tab SHALL follow the Ink mockup values in this change's design.md: a two-button header, the due count and "cards due" on one row, an always-visible due bar with a count-first legend, a 60 pt Start review pill with an arrow, a 22 pt "Decks" heading, mockup-sized deck tiles, and a 64 pt floating tab bar.

#### Scenario: Default text size
- **WHEN** the Decks tab shows at the default Dynamic Type size
- **THEN** the header has exactly two round buttons (Sync, Add card), "cards due" sits on the same baseline as the due count, and the deck tiles show a coloured glyph, name, card count, coloured counts and a progress bar

#### Scenario: Nothing due
- **WHEN** no cards are due
- **THEN** the due bar shows as an empty track and the legend reads "0 new · 0 learning · 0 review"

### Requirement: Streak on home
The home subline SHALL show the study streak, from the same engine-backed value the Stats tab uses.

#### Scenario: Studied three days in a row
- **WHEN** the user has reviewed cards on each of the last three days, including today
- **THEN** the subline ends with "3-day streak"

### Requirement: Import deck in Settings
Importing a deck package SHALL be reachable from Settings › Import and export, and from the home screen's empty state.

#### Scenario: Importing a deck
- **WHEN** the user opens Settings › Import and export
- **THEN** an "Import deck" row opens the file picker for `.apkg` and `.colpkg` files
