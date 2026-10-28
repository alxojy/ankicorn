## ADDED Requirements

### Requirement: Simple deck screen
The deck screen SHALL show the deck's counts on one line, Study as its only large button, secondary actions in the ⋯ menu, and subdecks as compact rows.

#### Scenario: Opening a parent deck
- **WHEN** the user opens a deck with four subdecks
- **THEN** the counts line, the Study button and all four subdeck rows fit on one screen

#### Scenario: Secondary actions
- **WHEN** the user taps ⋯ on the deck screen
- **THEN** Custom study, Browse cards, Deck options, Rename and Delete are listed, and Unbury too when the deck has buried cards

#### Scenario: Nothing due
- **WHEN** the deck has no cards due
- **THEN** the Study button reads "Nothing due" and is disabled, with a Custom study link under it
