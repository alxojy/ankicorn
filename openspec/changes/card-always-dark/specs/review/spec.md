## MODIFIED Requirements

### Requirement: Imported note types render readably
Cards from imported note types SHALL keep their own CSS for layout, fonts and sizes. By default (Card colours: App), a card whose note type sets a light background SHALL show on the dark Ink card with light text, keeping the hues of coloured text and the real colours of pictures, without changing the note type. With Card colours set to Note type's own, a light card SHALL keep its background with dark default text, as on desktop. Default text SHALL never be unreadable against the card's background.

#### Scenario: Light background, default App colours
- **WHEN** the user reviews a card whose note type sets `.card { background-color: #fdf6e3 }` and no text colour, with Card colours set to App
- **THEN** the card is the dark Ink colour, the headword and meaning are light, the pinyin is still green, a picture shows its real colours, and the note type's CSS in the collection is unchanged

#### Scenario: Light background, no text colour
- **WHEN** Card colours is set to Note type's own and the user reviews a card whose note type sets `.card { background-color: #fdf6e3 }` and no colour
- **THEN** the headword, meaning and sentence show as dark text on the cream card

#### Scenario: No styling
- **WHEN** a note type sets no background
- **THEN** the card uses the Ink look
