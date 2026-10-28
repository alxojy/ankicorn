## ADDED Requirements

### Requirement: Delete a deck
The user SHALL be able to delete a deck from its tile or overview, after a confirmation that states how many cards will be deleted, and SHALL be able to undo the deletion straight away.

#### Scenario: Deleting a deck
- **WHEN** the user long-presses the "HSK 2" tile, chooses Delete and confirms
- **THEN** the engine removes the deck, its subdecks and its cards, the tile disappears, and an Undo toast appears

#### Scenario: Undoing a deletion
- **WHEN** the user taps Undo in the toast
- **THEN** the deck and its cards come back with their scheduling intact

#### Scenario: Default deck
- **WHEN** the user long-presses the Default deck
- **THEN** Delete isn't offered

### Requirement: Rename a deck
The user SHALL be able to rename a deck. Using `::` in the name makes it a subdeck, as in Anki.

#### Scenario: Renaming
- **WHEN** the user renames "HSK 2" to "HSK 2b"
- **THEN** the tile shows "HSK 2b", and the change syncs like any other collection change
