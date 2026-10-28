# sync Specification

## Purpose
AnkiWeb sync of the collection and media, the full-sync choice, automatic backups, and the Settings tab with account and basic preferences.

## Requirements

### Requirement: AnkiWeb login
The app SHALL log in with `sync_login` from a sheet and store only the returned hkey in the Keychain. Credentials MUST NOT be stored or committed.

#### Scenario: Log in
- **WHEN** the user submits valid credentials
- **THEN** the hkey is saved in the Keychain and the account shows as signed in

### Requirement: Collection and media sync
The Sync button and pull-to-refresh on Decks SHALL run `sync_collection` then `sync_media`, show progress from `latest_progress`, and update a quiet "Synced N min ago" status line.

#### Scenario: Normal sync
- **WHEN** the user taps Sync while signed in
- **THEN** the collection and media sync and the status line shows the sync time

### Requirement: Full sync choice
When the engine requires a full sync the app SHALL ask the user to upload or download, create a backup, then run `full_upload_or_download`.

#### Scenario: Choice required
- **WHEN** `sync_collection` reports a full sync is required
- **THEN** a prompt offers upload or download and nothing is overwritten before the user chooses

### Requirement: Backups
The app SHALL call `create_backup` into the app's Backups folder before a full sync and periodically after launch.

#### Scenario: Backup before full sync
- **WHEN** the user confirms a full sync
- **THEN** a backup is requested before the transfer starts

### Requirement: Settings
The Settings tab SHALL show the account with log in/out, sync options, and scheduling and review preferences read and written with `get_preferences` / `set_preferences`.

#### Scenario: Change a preference
- **WHEN** the user changes the learn-ahead limit
- **THEN** it is saved through `set_preferences`

### Requirement: HTTPS to AnkiWeb
The engine built into the app SHALL include a TLS backend, so login, sync and media sync can reach AnkiWeb over HTTPS.

#### Scenario: Login with wrong credentials
- **WHEN** the user logs in with an email and password that AnkiWeb rejects, on a working network
- **THEN** the app shows AnkiWeb's authentication error, not "A network error occurred"

#### Scenario: Login with valid credentials
- **WHEN** the user logs in with a valid AnkiWeb account on a working network
- **THEN** the login succeeds and a sync key is stored in the Keychain

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

### Requirement: Sign-in state updates immediately
Every screen that shows the AnkiWeb account state SHALL update as soon as the user logs in or out, without leaving the screen.

#### Scenario: Logging in from Settings
- **WHEN** the user logs in successfully from Settings
- **THEN** the login sheet closes and Settings shows "Signed in as <username>" and a Log out button straight away

#### Scenario: Logging out
- **WHEN** the user logs out
- **THEN** Settings shows "Log in to AnkiWeb" and the Decks header shows "Not signed in" straight away
