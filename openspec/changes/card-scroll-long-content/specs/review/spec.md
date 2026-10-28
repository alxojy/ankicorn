## ADDED Requirements

### Requirement: Long cards scroll inside the card
When a rendered card is taller than the space for it, the user SHALL be able to scroll it vertically inside the card frame, while horizontal swipes still grade and taps still reveal or open pictures. Each card and each reveal SHALL start at the top, or at the answer divider when it is below the fold.

#### Scenario: Picture below the fold
- **WHEN** the answer side of a card ends with a picture that doesn't fit in the card frame
- **THEN** the user can scroll down inside the card until the whole picture is visible, and a fade at the bottom edge shows there is more until they reach the end

#### Scenario: Swipe still grades
- **WHEN** the user drags a long card mostly sideways
- **THEN** the card follows the drag and grades as before, and the card content doesn't scroll

#### Scenario: Next card starts at the top
- **WHEN** the user grades a scrolled card
- **THEN** the next card shows from its top

### Requirement: Replay button overlays the card corner
The replay button SHALL float over the bottom-right corner of the card on a small material background, without reserving a strip of card height, and card content SHALL be able to scroll clear of it.

#### Scenario: Card with audio
- **WHEN** a card with audio is shown
- **THEN** the replay button sits in the card's bottom-right corner and the card content uses the full card height
