## ADDED Requirements

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
