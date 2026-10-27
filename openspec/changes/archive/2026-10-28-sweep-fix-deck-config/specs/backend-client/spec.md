## ADDED Requirements

### Requirement: New decks use the engine template
The app SHALL create decks from the engine's `new_deck` template, so every new deck references an existing options preset.

#### Scenario: Seeded sample deck
- **WHEN** the sample collection is seeded and the user opens Card info for an HSK 1 card
- **THEN** the card's statistics are shown, with no inconsistent-database error
