## ADDED Requirements

### Requirement: Sign-in state updates immediately
Every screen that shows the AnkiWeb account state SHALL update as soon as the user logs in or out, without leaving the screen.

#### Scenario: Logging in from Settings
- **WHEN** the user logs in successfully from Settings
- **THEN** the login sheet closes and Settings shows "Signed in as <username>" and a Log out button straight away

#### Scenario: Logging out
- **WHEN** the user logs out
- **THEN** Settings shows "Log in to AnkiWeb" and the Decks header shows "Not signed in" straight away
