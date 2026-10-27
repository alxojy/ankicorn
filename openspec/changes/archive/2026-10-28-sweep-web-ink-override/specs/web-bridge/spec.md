## ADDED Requirements

### Requirement: Ink styling reaches every control
Hosted Anki pages SHALL style primary buttons, radios, checkboxes, switches, tab underlines and selects with the Ink tokens, through injected CSS only.

#### Scenario: Deck options page
- **WHEN** the deck options page is open
- **THEN** the Save button, the selected preset tab and the switches use the Ink accent, and no Bootstrap blue is visible

#### Scenario: Stats page
- **WHEN** the More stats page is open
- **THEN** the selected radio buttons use the Ink accent
