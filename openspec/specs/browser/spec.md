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

### Requirement: Answer line without the question
In cards mode, the Browse row's secondary line SHALL show the card's answer without repeating the question, with separators between fields.

#### Scenario: Chinese vocab card row
- **WHEN** Browse lists the Hanzi → English card for 你好
- **THEN** the row title is "你好", and the secondary line starts with "hello", not with "你好"

#### Scenario: Example sentence fields stay apart
- **WHEN** a row's answer includes the example sentence, its pinyin and its English
- **THEN** the three appear separated (for example by " · "), not glued together

### Requirement: Search field clear of the tab bar
The Browse search field SHALL sit at the top of the screen under the title, and SHALL NOT overlap the floating tab bar.

#### Scenario: Opening Browse
- **WHEN** the user opens the Browse tab
- **THEN** "Search cards" shows under the Browse title, and nothing at the bottom overlaps the tab bar
