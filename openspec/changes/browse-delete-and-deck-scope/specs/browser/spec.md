## ADDED Requirements

### Requirement: Browse by deck
Browse SHALL show which deck it is scoped to and let the user change it from the main screen. Opening Browse from a deck SHALL scope it to that deck.

#### Scenario: Picking a deck
- **WHEN** the user taps the deck chip and picks "HSK 2"
- **THEN** the list shows only HSK 2's cards (including subdecks), and the count line names HSK 2

#### Scenario: From a deck
- **WHEN** the user taps "Browse cards" on the HSK 1 overview
- **THEN** the Browse tab opens scoped to HSK 1

### Requirement: Multi-select delete
In selection mode, Browse SHALL show a reachable action bar with Delete. Deleting SHALL confirm with counts and offer Undo.

#### Scenario: Deleting selected notes
- **WHEN** the user selects two rows and taps Delete, then confirms
- **THEN** those notes and their cards are deleted, the list updates, and an Undo toast appears

#### Scenario: Action bar is reachable
- **WHEN** selection mode is on
- **THEN** the Delete button is fully visible and tappable, with nothing overlapping it
