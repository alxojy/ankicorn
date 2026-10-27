## ADDED Requirements

### Requirement: Start review studies all due decks
Start review (opened with no deck) SHALL study cards from every deck that has due cards, using due counts from `deck_tree`. It SHALL set each such deck current in turn and show the congrats screen only when no deck has due cards left.

#### Scenario: Cards due in a non-current deck
- **WHEN** HSK 1 has 45 new cards, the engine's current deck is the empty Default deck, and the user taps Start review
- **THEN** the review screen shows an HSK 1 question, not the congrats screen
