## MODIFIED Requirements

### Requirement: Imported note types render readably
Cards from imported note types SHALL keep their own CSS for layout, fonts and sizes, but SHALL always show on the Ink card colour in the app: the note type's background colours and images SHALL NOT be shown, default text SHALL be the Ink text colour, and any text colour below WCAG AA against the Ink card SHALL be replaced (greys by the Ink text or muted colour, coloured text lightened in the same hue). Pictures SHALL keep their real colours. The note type in the collection SHALL NOT change.

#### Scenario: Light background, no text colour
- **WHEN** the user reviews a card whose note type sets `.card { background-color: #fdf6e3 }` and no colour
- **THEN** the card shows on the dark Ink card with light headword, meaning and sentence text, no cream anywhere, and the note type's CSS in the collection is unchanged

#### Scenario: Coloured text on a light note type
- **WHEN** the note type colours its pinyin `#005500`
- **THEN** the pinyin shows green and readable (at least WCAG AA) on the Ink card, and a picture on the card shows its real colours

#### Scenario: No styling
- **WHEN** a note type sets no background
- **THEN** the card uses the Ink look
