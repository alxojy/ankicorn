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
