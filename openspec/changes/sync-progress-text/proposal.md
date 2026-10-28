## Why
User: "when syncing it says syncing syncing… why".

Cause, in `SyncModel.describe`: for normal-sync progress it returns `"Syncing \(value.stage)…"`. But the engine's `stage` is already a full translated phrase (`rslib/src/progress.rs`: Connecting and Syncing map to `sync-syncing` = "Syncing...", Finalizing maps to `sync-checking` = "Checking..."). So the status reads "Syncing Syncing...…" and then "Syncing Checking...…".

The engine also sends `added` and `removed` lines ("Added/modified: 3↓ 2↑"), and media sync sends its own checked/added/removed text. We drop both and show a bare "Syncing media…", so a long sync looks frozen.

## What Changes
- **Use the engine's text as given:**
  - **Normal sync:** the stage string as is ("Syncing...", "Checking..."), with the engine's three dots turned into one "…" character for the Ink type. No prefix.
  - **Counts:** when the `added` or `removed` lines are non-empty and not zero, they show as a second, muted line.
- **Media sync progress:** show the engine's media progress text (checked, added, removed counts) instead of a fixed "Syncing media…", so the user can see it moving.
- **Full sync:** keep "Uploading 42%" / "Downloading 42%".
- **One place shows it:** the same text appears in the home header status and in Settings › Sync now. Neither screen adds its own "Syncing" prefix.

## Impact
`Sync/SyncModel.swift` (`describe`, the media progress case, a detail line in the phase), the home header and the Settings Sync now row, and tests.
