## ADDED Requirements

### Requirement: Filtered decks
The app SHALL create and edit filtered decks from a search, limit and order using the engine, and rebuild or empty them.

#### Scenario: Create and rebuild
- **WHEN** the user saves a filtered deck with a search
- **THEN** the engine creates it, pulling in matching cards, and Rebuild repeats the pull

#### Scenario: Empty
- **WHEN** the user taps Empty
- **THEN** the cards return to their home decks

### Requirement: Tag management
The app SHALL list all tags and rename, reparent and delete them, and clear unused tags, using the engine.

#### Scenario: Rename
- **WHEN** the user renames a tag
- **THEN** every note using it carries the new name

### Requirement: Note type editing
The app SHALL list note types with use counts and edit their fields, card templates and styling with `get_notetype` and `update_notetype`.

#### Scenario: Add a field
- **WHEN** the user adds a field and saves
- **THEN** the note type has the new field

### Requirement: Find and replace and duplicates
The Browse tab SHALL replace text in the selected notes with the engine's find and replace, and find duplicate notes by a note type's first field.

#### Scenario: Replace
- **WHEN** the user replaces text in selected notes
- **THEN** the engine reports how many notes changed
