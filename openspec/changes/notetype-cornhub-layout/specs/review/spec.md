## ADDED Requirements

### Requirement: Imported cards in the Cornhub layout
A card whose note type uses the Cornhub layout SHALL show, on the answer side, the picture at the top, the hanzi large with accent pinyin beside it, a hairline, the meaning, and the example sentence with the headword highlighted, its pinyin and meaning muted; the question side SHALL show the hanzi centred.

#### Scenario: Answer side of an imported card
- **WHEN** the user reveals a card of a note type converted to the Cornhub layout
- **THEN** the card matches the mockup's Review layout on the Ink card, and replay and Speak still work
