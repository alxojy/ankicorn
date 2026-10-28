## ADDED Requirements

### Requirement: Sync progress text from the engine
While syncing, the app SHALL show the engine's own progress text without adding words to it, including the engine's change counts and media progress when available.

#### Scenario: Normal sync
- **WHEN** a normal sync is running and the engine reports the stage "Syncing..."
- **THEN** the status reads "Syncing…", not "Syncing Syncing…"

#### Scenario: Finalizing
- **WHEN** the engine reports the stage "Checking..."
- **THEN** the status reads "Checking…"

#### Scenario: Media sync
- **WHEN** media is syncing
- **THEN** the status shows the engine's media progress counts as they change
