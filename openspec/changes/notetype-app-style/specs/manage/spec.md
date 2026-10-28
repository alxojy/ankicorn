## ADDED Requirements

### Requirement: Restyle a note type to the app style
The app SHALL let the user rewrite a note type's CSS to the Cornhub (Ink) style, with a preview, through the engine so that it syncs to desktop. The previous CSS SHALL be recoverable.

#### Scenario: Restyling an imported deck
- **WHEN** the user picks "Use Cornhub style" for a note type with a cream `.card` background and applies it
- **THEN** its cards render as the dark Ink card with Ink type, and after a normal sync desktop shows the new style too

#### Scenario: Going back
- **WHEN** the user picks "Restore original style"
- **THEN** the note type's previous CSS is restored

#### Scenario: Desktop light mode
- **WHEN** the restyled cards are shown in desktop Anki's light mode
- **THEN** the text is dark and readable
