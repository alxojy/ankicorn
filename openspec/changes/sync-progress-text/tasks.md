## 1. Fix
- [ ] 1.1 `describe` uses the engine's normal-sync stage as is (trailing "..." → "…"), no "Syncing" prefix; non-zero added/removed lines become a muted detail line
- [ ] 1.2 Media sync shows the engine's media progress text (checked/added/removed) instead of a fixed string
- [ ] 1.3 Home header and Settings Sync now show the same text without adding their own prefix

## 2. Proof
- [ ] 2.1 Unit tests on `describe` with progress messages shaped like the engine's: stage "Syncing..." gives "Syncing…" (never "Syncing Syncing"), "Checking..." gives "Checking…", added/removed lines pass through, media progress text passes through, full sync percentages unchanged
- [ ] 2.2 A Rust test or Swift test against the local rslib sync server (as in `fix-full-sync`) captures at least one normal-sync progress during a sync and the rendered status contains no doubled word
