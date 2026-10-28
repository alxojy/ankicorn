## ADDED Requirements

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
