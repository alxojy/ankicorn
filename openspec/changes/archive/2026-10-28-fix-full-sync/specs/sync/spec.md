## ADDED Requirements

### Requirement: Full sync choice runs
When a sync needs a full transfer, choosing Download or Upload SHALL start that transfer, show its progress, and end with the collection open and the screens refreshed, or with a visible error.

#### Scenario: Download from AnkiWeb
- **WHEN** the sync prompt offers a full transfer and the user taps "Download from AnkiWeb"
- **THEN** a backup is made, the collection downloads with progress shown, media syncs if enabled, and the Decks tab shows the downloaded decks

#### Scenario: Transfer fails
- **WHEN** the transfer fails (for example the network drops)
- **THEN** the app shows the engine's error, and the existing collection is still open and usable

### Requirement: Standard full sync prompt
The full-sync prompt SHALL use short, equally sized standard buttons ("Download from AnkiWeb", "Upload to AnkiWeb", "Cancel") and explain in its message what each one replaces.

#### Scenario: Prompt layout
- **WHEN** the prompt shows
- **THEN** all buttons use the same system text size with no parenthetical text, and the message says which side each choice replaces
