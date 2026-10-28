## Why
The user reports that tapping "Download from AnkiWeb (replaces this device)" in the full-sync prompt does nothing. Also, the prompt's buttons render at different text sizes.

Causes the orchestrator found by reading the code (the worker must confirm each one):
1. **The choice is cleared before it's used.** `DeckHomeScreen` binds the `confirmationDialog` with `isPresented: Binding(get: { sync.fullSyncChoice != nil }, set: { if !$0 { sync.cancelFullSync() } })`. Tapping a button dismisses the dialog first, so the setter runs `cancelFullSync()`, which clears `fullSyncChoice` and `pendingAuth`. The button action `resolve()` only schedules a `Task`. When `resolveFullSync()` runs, `guard let choice = fullSyncChoice, let auth = pendingAuth else { return }` returns silently. Nothing happens and no error shows.
2. **The collection is reopened twice.** rslib's `full_upload_or_download` (`rslib/src/backend/sync.rs`) already reopens the collection ("ensure re-opened regardless of outcome"). `SyncModel.resolveFullSync` then calls `reopenCollection()`, which is `DeckHomeModel.reopen()` → `backend.openCollection`. That call would probably fail with "collection already open" after a successful download, and the error path calls it again.
3. **Media isn't synced after a full transfer.** Desktop Anki runs a media sync after a full sync. Ours passes `serverUsn` but never calls `syncMedia` after the transfer, so pictures and audio don't arrive.
4. **The button labels shrink unevenly.** iOS shrinks long confirmation-dialog labels to fit, so "Download from AnkiWeb (replaces this device)" renders smaller than the other buttons.

## What Changes
- Keep the full-sync choice until the user's action has been dispatched. Use `confirmationDialog(_:isPresented:titleVisibility:presenting:)` with the choice and auth passed into the button actions, or capture them before dismissal. Only the Cancel button (or a real dismissal without a choice) cancels. `resolveFullSync` gets what it needs as parameters and never returns silently: a missing state becomes a visible error.
- After `fullUploadOrDownload`, don't call `openCollection`; just refresh the screens (`DeckHomeModel.refresh()` / `didFinish`). On failure, show the engine's error. Check that the collection is open (`refresh` works) after both success and failure.
- After a successful full transfer, run `syncMedia` when "Sync media" is on, with progress shown ("Syncing media…"), as a normal sync does.
- **Standard dialog:** the title is "Sync conflict" or "Choose what to keep". Buttons: **"Download from AnkiWeb"**, **"Upload to AnkiWeb"** and **"Cancel"**: short, the same system size, no parentheses. The message explains: "This device and AnkiWeb can't be merged. Download replaces this device's collection with AnkiWeb's. Upload replaces AnkiWeb's collection with this device's. A backup of this device is made first." Download comes first, since it's the common case on a new phone. Show only the buttons the engine allows (`fullDownload` / `fullUpload` / `fullSync`). Use the destructive role only where data is replaced, and keep it consistent across both buttons.
- While transferring, the Decks header status shows the progress ("Downloading 42%"), and Sync is disabled.

## Impact
`app/Cornhub/Sync/SyncModel.swift`, `Screens/DeckHome/DeckHomeScreen.swift`, `DeckHomeModel.swift`, `Screens/Shell/AppShell.swift`, and a test in `crates/rslib-bridge` or `app/CornhubTests`. Tests never contact AnkiWeb or use a real account.
