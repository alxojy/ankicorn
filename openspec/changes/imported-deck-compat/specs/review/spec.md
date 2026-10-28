## ADDED Requirements

### Requirement: Imported note types render readably
Cards from imported note types SHALL keep their own CSS. When a note type sets a light card background without a text colour, the default text SHALL be dark, as on desktop. Default text SHALL never be unreadable against the card's own background.

#### Scenario: Light background, no text colour
- **WHEN** the user reviews a card whose note type sets `.card { background-color: #fdf6e3 }` and no colour
- **THEN** the headword, meaning and sentence show as dark text on the cream card

#### Scenario: No styling
- **WHEN** a note type sets no background
- **THEN** the card uses the Ink look

### Requirement: Imported media plays and shows
Images and sounds referenced by imported notes SHALL load from the collection's media folder. A missing image SHALL show an Ink placeholder instead of a broken-image icon.

#### Scenario: Sentence image
- **WHEN** a card's field has `<img src="x.jpg">` and `x.jpg` was imported with the deck
- **THEN** the image shows on the card

#### Scenario: Missing image
- **WHEN** the referenced image file isn't in the media folder
- **THEN** a small "Image missing" placeholder shows

### Requirement: Extras work on any note type
Speak, Explain, Translate and stroke order SHALL work on cards of any note type, using the note's audio when present and otherwise the card's own text.

#### Scenario: Speak on an imported card
- **WHEN** the user taps Speak on an imported card whose `Audio` field has `[sound:word.mp3]`
- **THEN** the sound plays, or if the file is missing, the headword is spoken with text-to-speech

#### Scenario: Speak on a note type without audio
- **WHEN** the note type has no sound fields
- **THEN** Speak says only the headword, derived from the first mostly-hanzi field
