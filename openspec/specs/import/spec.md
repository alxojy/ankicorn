# import Specification

## Purpose
Getting existing decks onto the phone: importing Anki packages, the bundled Chinese vocab note type and the demo sample notes.

## Requirements

### Requirement: Import Anki packages
The app SHALL import `.apkg` files with `import_anki_package` and `.colpkg` files with `import_collection_package` (closing and reopening the collection around it), from a Files picker and as an "Open in" document type, showing progress while it runs and a summary (new, updated, duplicate notes) afterwards.

#### Scenario: Import a deck
- **WHEN** the user picks an `.apkg` file
- **THEN** the notes are imported by the engine and a summary of new and updated notes is shown

### Requirement: Chinese vocab note type
The app SHALL add a "Chinese vocab (2-way)" note type if missing when the collection opens, with fields Hanzi, Pinyin, English, Picture, Example, Example pinyin, Example English and Audio, two cards (hanzi to English, English to hanzi) and Ink-styled CSS.

#### Scenario: First launch
- **WHEN** the collection opens without that note type
- **THEN** it is created exactly once

### Requirement: Sample notes
The `--seed-sample` launch path SHALL add about 20 Chinese notes and 2 Basic and 2 Cloze notes to the sample decks, only when the sample decks hold no notes.

#### Scenario: Seeded twice
- **WHEN** the app launches twice with `--seed-sample`
- **THEN** the notes are not duplicated
