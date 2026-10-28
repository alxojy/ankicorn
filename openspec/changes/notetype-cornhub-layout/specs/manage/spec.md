## ADDED Requirements

### Requirement: Cornhub layout for an existing note type
The app SHALL offer to rewrite a note type's card templates and CSS to the Cornhub review layout using the note type's own fields, after the user confirms a field mapping, without adding, removing or renaming fields or changing note content. The change SHALL be undoable and restorable, and SHALL reach desktop through a normal sync.

#### Scenario: Apply to an imported HSK note type
- **WHEN** the user opens an imported note type with fields Simplified, Pinyin.1, Meaning, SentenceSimplified, SentencePinyin.1, SentenceMeaning, SentenceImage and Audio and taps Use Cornhub layout, confirms the guessed mapping and applies
- **THEN** the note type's templates show the Cornhub layout, its field list is unchanged, and its notes are unchanged

#### Scenario: Unmapped fields are named
- **WHEN** the mapping leaves some fields without a role
- **THEN** the sheet lists them as not shown on the card before the user applies

#### Scenario: Restore
- **WHEN** the user taps Restore original layout
- **THEN** the note type's previous templates and CSS are back exactly
