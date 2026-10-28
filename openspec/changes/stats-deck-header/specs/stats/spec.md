## ADDED Requirements

### Requirement: Deck header fits the screen
The Stats deck header SHALL show the selected deck's own name on one line within the screen width, truncating with an ellipsis if needed, with the parent path as a caption for subdecks. Deck paths SHALL NOT be shown with raw `::` separators.

#### Scenario: Subdeck with a long parent
- **WHEN** the user picks "Mandarin (HSK)::一. HSK1" in Stats
- **THEN** the header shows "一. HSK1" with "Mandarin (HSK)" as a caption above it, nothing is clipped, and the chevron is visible

#### Scenario: Picking a deck
- **WHEN** the user opens the deck picker
- **THEN** decks are listed by name under their parents, with the current deck checked
