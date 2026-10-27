## Why
Cornhub cannot yet exchange reviews with desktop Anki. Phase 2 adds AnkiWeb sync, backups and basic preferences.

## What Changes
- AnkiWeb login sheet (`sync_login`); the hkey is kept in the Keychain, never credentials in the repo.
- Sync button and pull-to-refresh on Decks run `sync_collection` then `sync_media`, with progress from `latest_progress`.
- Quiet status line ("Synced 2 min ago") and a full-sync choice prompt (upload vs download).
- Automatic backups (`create_backup`) before a full sync and after launch/sync.
- Settings tab: account (log in/out), sync options, scheduling and review preferences (`get_preferences` / `set_preferences`).
