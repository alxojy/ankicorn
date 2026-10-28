## ADDED Requirements

### Requirement: Missing images are hidden
A card image whose file is missing SHALL be left out of the card with no placeholder or broken-image icon.

#### Scenario: Image file not on the phone
- **WHEN** a card's `<img>` points at a file that isn't in the media folder
- **THEN** nothing is shown in its place and no empty gap is left at the end of the card

### Requirement: Replay button stays off the card
The note-audio replay button SHALL sit in the app's chrome and SHALL NOT overlap the card's content.

#### Scenario: Card with its own background
- **WHEN** a card with a deck-styled box has note audio
- **THEN** the replay button is shown outside that box

### Requirement: Translate chooses languages from the card
Translate SHALL detect the source language from the card's text and translate into the device language, and SHALL show a friendly message instead of a raw error when translation isn't possible.

#### Scenario: Chinese card in a deck without a speech language
- **WHEN** the user taps Translate on a Chinese card whose deck has no speech language set
- **THEN** the card is translated from Chinese into the device language

#### Scenario: Language pack not available
- **WHEN** the language pair isn't available on the device
- **THEN** a short message explains how to get it, in the app's style

### Requirement: Explain works on Chinese cards
Explain SHALL send the on-device model a compact prompt built from the card's headword, pinyin, meaning and one example, with instructions in the device language, and SHALL NOT show the raw model error when the language isn't supported.

#### Scenario: Imported Chinese card
- **WHEN** the user taps Explain on an imported Chinese card
- **THEN** an explanation appears in the device language

#### Scenario: Model rejects the language
- **WHEN** the model reports an unsupported language even after a romanised retry
- **THEN** a short message in the app's style says Explain isn't available in this language on this device
