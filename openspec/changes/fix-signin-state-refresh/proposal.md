## Why
The user reports that after logging in, Settings still shows "Log in to AnkiWeb". It only switches to the account and Log out after leaving the tab and coming back.

Cause, found by reading the code: `SyncModel.isSignedIn` is computed as `store.hkey != nil`, a Keychain read through `AccountStore`, a `let` struct. Observation doesn't track it. `login` updates `username`, which is tracked, but `SettingsScreen` reads `username` only inside the `if sync.isSignedIn` branch. The logged-out branch depends on nothing that changes, so SwiftUI never redraws it. The Decks header status ("Not signed in", from `statusText`) and the Sync button's `.disabled(!sync.isSignedIn …)` go stale the same way.

## What Changes
- `SyncModel` keeps sign-in state as an observed stored property (for example `private(set) var isSignedIn: Bool`), set from the Keychain in `init` and updated in `login` and `logout`. `statusText`, Settings and the Sync button read it.
- The hkey is still read from the Keychain where it's used (`sync`); the observed flag only drives the UI.
- After a successful login, the login sheet closes and Settings shows "Signed in as …" with Log out straight away. The Decks header switches to "Not synced yet".

## Impact
`app/Cornhub/Sync/SyncModel.swift`, maybe `LoginSheet.swift`. Tests never contact AnkiWeb.
