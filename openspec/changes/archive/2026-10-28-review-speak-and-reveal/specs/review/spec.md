## ADDED Requirements

### Requirement: Speak pronounces the word only
The Speak action SHALL play the note's own audio when it has any, and otherwise speak only the card's headword. It SHALL NOT read pinyin, translations or example sentences.

#### Scenario: Chinese vocab card without audio
- **WHEN** the user taps Speak on a 你好 card whose Audio field is empty
- **THEN** the device speaks "你好" only

#### Scenario: Card with audio
- **WHEN** the note's Audio field holds `[sound:nihao.mp3]`
- **THEN** Speak plays that file instead of TTS

### Requirement: Show answer capsule
On the question side, the review screen SHALL show a single "Show answer" capsule where the grade bar goes, and SHALL NOT show disabled grade buttons.

#### Scenario: Before reveal
- **WHEN** a card's question is showing
- **THEN** a "Show answer" capsule sits at the bottom and no Again, Hard, Good or Easy buttons are visible

#### Scenario: Reveal
- **WHEN** the user taps the capsule or the card
- **THEN** the answer shows and the capsule turns into the four grade buttons with their intervals
