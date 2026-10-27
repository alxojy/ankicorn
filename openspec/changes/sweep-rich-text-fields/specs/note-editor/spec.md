## ADDED Requirements

### Requirement: Rich text fields
The note editor SHALL show field formatting (bold, italic, underline, line breaks) as styled text, not as HTML tags, and SHALL save fields back as HTML without losing markup it does not display.

#### Scenario: Editing a field with bold text
- **WHEN** the user opens a note whose field is `<b>明天</b>见`
- **THEN** the field shows "明天见" with "明天" in bold, and no `<b>` tag is visible

#### Scenario: Applying bold
- **WHEN** the user selects text in a field and taps Bold
- **THEN** the selected text becomes bold, and the saved field wraps it in `<b>…</b>`

#### Scenario: Unsupported markup is preserved
- **WHEN** a field contains markup the editor cannot display, such as `<img>`, `[sound:…]` or a styled `<span>`
- **THEN** saving the note keeps that markup unchanged
