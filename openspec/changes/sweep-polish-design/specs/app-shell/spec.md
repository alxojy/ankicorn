## ADDED Requirements

### Requirement: Display face usage
Big numbers, screen titles, count rows, the English answer on cards and the grade stamp SHALL use the Space Grotesk display face, scaled with Dynamic Type.

#### Scenario: Home hero
- **WHEN** the Decks tab shows "45 cards due"
- **THEN** the number and the deck tile counts render in Space Grotesk

### Requirement: Floating grade bar
The review grade bar SHALL float above the content as a dark glass capsule with a hairline border, matching the tab bar, and the next card SHALL peek out behind the current card.

#### Scenario: Answer side
- **WHEN** the answer is revealed
- **THEN** the four grade buttons sit in a glass capsule, and the edge of the next card is visible behind the current one
