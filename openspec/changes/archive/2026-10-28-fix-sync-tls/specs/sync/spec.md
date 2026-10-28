## ADDED Requirements

### Requirement: HTTPS to AnkiWeb
The engine built into the app SHALL include a TLS backend, so login, sync and media sync can reach AnkiWeb over HTTPS.

#### Scenario: Login with wrong credentials
- **WHEN** the user logs in with an email and password that AnkiWeb rejects, on a working network
- **THEN** the app shows AnkiWeb's authentication error, not "A network error occurred"

#### Scenario: Login with valid credentials
- **WHEN** the user logs in with a valid AnkiWeb account on a working network
- **THEN** the login succeeds and a sync key is stored in the Keychain
