# note-editor Specification

## Purpose
Add new cards and edit existing notes in one native full-screen editor: deck and note-type pickers, fields that follow the note type, media, tags, sticky fields and formatting.

## Requirements

### Requirement: Add card screen
The app SHALL provide a full-screen Add card editor with deck and note-type chips, one field block per note-type field, a tags row and an Add card button, using `defaults_for_adding` for the initial deck and note type.

#### Scenario: Add a note
- **WHEN** the user fills the fields and taps Add card
- **THEN** the engine adds the note, the fields clear (except sticky ones) and the deck and note type stay selected

#### Scenario: Chinese note type
- **WHEN** the selected note type is Chinese vocab (2-way)
- **THEN** Hanzi sits beside a picture tile, Pinyin and English sit side by side and Example is below

### Requirement: Media and formatting
The editor SHALL insert photos, camera pictures and recorded audio as media files stored through the engine, and SHALL offer bold, italic, underline and cloze formatting.

#### Scenario: Record audio
- **WHEN** the user records audio into a field
- **THEN** the recording is added as a media file and `[sound:name]` is appended to the field

### Requirement: Edit existing notes
The same editor SHALL edit an existing note and save it with `update_notes`.

#### Scenario: Edit from review
- **WHEN** the user chooses Edit note in the review menu
- **THEN** the editor opens with the note's fields and tags and saving updates the note

### Requirement: Keyboard layout
With the keyboard up, the formatting toolbar and the Add card button SHALL NOT overlap each other or the fields.

#### Scenario: Typing in the first field
- **WHEN** the user types in the first field
- **THEN** the formatting toolbar sits above the keyboard, and the Add card button stays fully visible or reachable without overlap

### Requirement: Rich text fields
The note editor SHALL show field formatting (bold, italic, underline, line breaks) as styled text, not as HTML tags, and SHALL save fields back as HTML without losing markup it does not display.

#### Scenario: Editing a field with bold text
- **WHEN** the user opens a note whose field is `<b>明天</b>见`
- **THEN** the field shows "明天见" with "明天" in bold, and no `<b>` tag is visible

#### Scenario: Applying bold
- **WHEN** the user selects text in a field and taps Bold
- **THEN** the selected text becomes bold, and the saved field wraps it in `<b>…</b>`

#### Scenario: Unsupported markup is preserved
- **WHEN** a field contains markup the editor cannot display, such as `<img>`, `[sound:…]` or a styled `<span>`
- **THEN** saving the note keeps that markup unchanged
