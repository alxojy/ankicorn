## ADDED Requirements

### Requirement: Stroke order for the card's word
Stroke order SHALL show only the hanzi of the card's headword, in a single row that fits the panel without clipping.

#### Scenario: Card with an example sentence
- **WHEN** the user taps Stroke order on the 怎么样 card whose answer also has the sentence 这件衣服怎么样？
- **THEN** only 怎, 么 and 样 are shown

#### Scenario: Headword without hanzi
- **WHEN** the card's headword has no hanzi
- **THEN** the Stroke order button isn't shown
