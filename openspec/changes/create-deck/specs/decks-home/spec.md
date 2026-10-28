## ADDED Requirements

### Requirement: Create a deck
The user SHALL be able to create a deck from the home screen's + menu and a subdeck from a deck's ⋯ menu, through the engine, with Undo.

#### Scenario: New deck
- **WHEN** the user taps + › New deck, types "Travel phrases" and taps Create
- **THEN** a "Travel phrases" deck appears on the home screen and an Undo toast shows

#### Scenario: New subdeck
- **WHEN** the user picks ⋯ › New subdeck… on "Travel phrases" and creates "Food"
- **THEN** "Travel phrases::Food" exists as a subdeck

#### Scenario: Name already taken
- **WHEN** the user enters the name of an existing deck
- **THEN** the sheet says a deck with that name already exists and nothing is created
