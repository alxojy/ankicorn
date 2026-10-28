## ADDED Requirements

### Requirement: Unbury when there is something to unbury
The deck overview SHALL offer Unbury only when the deck has buried cards, and SHALL confirm the result.

#### Scenario: Buried cards exist
- **WHEN** the deck has 3 buried cards and the user taps Unbury
- **THEN** the cards return to the queue, the counts update, "Unburied 3 cards" shows, and the Unbury button disappears

#### Scenario: Nothing buried
- **WHEN** the deck has no buried cards
- **THEN** no Unbury button shows
