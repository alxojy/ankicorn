## ADDED Requirements

### Requirement: Phone-styled dropdowns on hosted pages
Dropdowns on Anki's hosted pages, including the deck options preset picker, SHALL use the Ink look: a single-line, 44 pt field with a centred chevron, and an Ink list with 44 pt rows and an accent check on the selected item, drawn above the page content.

#### Scenario: Closed preset picker
- **WHEN** the user opens Deck options
- **THEN** "Default (used by 6 decks)" sits on one line, vertically centred, the same height as Save

#### Scenario: Open preset list
- **WHEN** the user taps the preset picker
- **THEN** an Ink list opens above the page with the current preset checked, and no blue highlight or left bar
