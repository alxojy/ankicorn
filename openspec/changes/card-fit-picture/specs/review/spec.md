## ADDED Requirements

### Requirement: Pictures fit the card
When a card overflows its frame only because of its pictures, the pictures SHALL shrink (keeping aspect ratio, not below 96 pt high) so the whole card fits without scrolling. The card SHALL scroll only when it still doesn't fit.

#### Scenario: Picture at the end of a card
- **WHEN** a card's text fits in the card frame but its picture would run past the bottom edge
- **THEN** the picture is shown whole inside the card, smaller, with no bottom fade and nothing to scroll

#### Scenario: Text alone is too long
- **WHEN** a card's text is taller than the card frame
- **THEN** the picture keeps its standard size and the card scrolls as before

#### Scenario: Replay button
- **WHEN** a card with audio and a picture is shown
- **THEN** the replay button is fully inside the card and doesn't cover the picture
