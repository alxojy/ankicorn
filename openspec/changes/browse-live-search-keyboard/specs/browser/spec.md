## ADDED Requirements

### Requirement: Live search
Browse SHALL filter as the user types, debounced, using the engine's search, and SHALL show all cards again when the search field is cleared.

#### Scenario: Typing a query
- **WHEN** the user types "hello" in Browse search without pressing return
- **THEN** shortly after the last keystroke the list shows only matching cards

#### Scenario: Clearing the field
- **WHEN** the user clears the search field
- **THEN** the list shows all cards in the current scope again

#### Scenario: Stale results
- **WHEN** an older search finishes after a newer one
- **THEN** the list keeps the newer search's results
