## ADDED Requirements

### Requirement: Standard picture size on cards
Pictures on cards SHALL fit within the card's width and a standard maximum height (about a third of the visible card, at most 220 pt), keeping their aspect ratio, whatever the note type's CSS says. Tapping a picture SHALL show it full screen.

#### Scenario: Tall answer with a picture
- **WHEN** the answer side shows a headword, a sentence, a translation and a landscape photo
- **THEN** the whole photo is visible inside the card at the standard size

#### Scenario: Deck CSS enlarges images
- **WHEN** the note type's CSS sets a large image size
- **THEN** the picture is still capped at the standard size

#### Scenario: Seeing the detail
- **WHEN** the user taps the picture
- **THEN** it opens full screen and can be zoomed, and closing it returns to the card
