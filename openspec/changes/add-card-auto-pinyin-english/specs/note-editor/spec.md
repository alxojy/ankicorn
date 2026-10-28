## ADDED Requirements

### Requirement: Pinyin and English fill themselves
On Add card with a Chinese note type, the editor SHALL fill Pinyin, and where possible English, from the hanzi as the user types, and SHALL keep both fields editable.

#### Scenario: Typing a word
- **WHEN** the user types 学生 into the Hanzi field
- **THEN** the Pinyin field shows "xué shēng" without further input, and English fills in when on-device translation or text generation is available

#### Scenario: The user's own text wins
- **WHEN** the user has typed their own English meaning and then changes the hanzi
- **THEN** the English field keeps the user's text, and only fields still holding auto-filled values update

#### Scenario: No translation available
- **WHEN** neither on-device translation nor text generation is available
- **THEN** Pinyin still fills, English stays empty, and no error is shown
