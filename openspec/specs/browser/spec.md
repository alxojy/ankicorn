# browser Specification

## Purpose
Find, preview and bulk-edit cards and notes: engine-backed search, sorting, filters, a previewer and multi-select actions.

## Requirements

### Requirement: Browse and search
The Browse tab SHALL list cards or notes matching a search typed by the user, using the engine's search and browser row methods, with a cards/notes toggle and a column sort.

#### Scenario: Search
- **WHEN** the user types a query
- **THEN** the list shows the rows the engine returns for it

#### Scenario: Sort
- **WHEN** the user picks a sort column
- **THEN** the search is re-run with that column as the engine sort order

### Requirement: Filter sheet
The Browse tab SHALL offer a sheet listing decks, tags, note types and flags that narrows the search.

#### Scenario: Filter by deck
- **WHEN** the user picks a deck in the sheet
- **THEN** the search includes that deck and the list updates

### Requirement: Open and preview
Tapping a row SHALL open the note editor, and a preview action SHALL render the card in the card web view.

#### Scenario: Preview
- **WHEN** the user taps Preview on a row
- **THEN** the card's question and answer are shown

### Requirement: Bulk actions
The user SHALL be able to select several rows and change deck, add or remove tags, reposition, set due date, forget, suspend or delete them through the engine.

#### Scenario: Change deck
- **WHEN** the user selects rows and chooses a deck
- **THEN** the engine moves those cards to the deck
