## 1. Debug
- [ ] 1.1 Reproduce "Download does nothing" with a test that drives the same sequence (dialog dismissal setter, then the button action) and fails on current main. Write down which causes from proposal.md you confirmed

## 2. Fix
- [ ] 2.1 The full-sync choice survives dismissal; `resolveFullSync` takes its inputs explicitly and never returns silently
- [ ] 2.2 No `openCollection` after a full transfer (the engine reopens); the screens refresh; errors are shown
- [ ] 2.3 A media sync runs after a successful full transfer when Sync media is on
- [ ] 2.4 The dialog uses short standard labels ("Download from AnkiWeb", "Upload to AnkiWeb", "Cancel") with the explanation in the message; progress shows while transferring

## 3. Proof
- [ ] 3.1 A Rust test in `crates/rslib-bridge` starts rslib's built-in sync server (`anki::sync::http_server`) on localhost with an invented `testuser` account. It logs in through the bridge, adds a note in collection A, full-uploads, then full-downloads into a fresh collection B through `run_method`. It checks that the note arrives and that B is usable without calling `open_collection` again. No AnkiWeb traffic.
- [ ] 3.2 A Swift unit test for the dismissal ordering (2.1) and the no-reopen path (2.2). Use a small protocol seam for the backend calls if needed
- [ ] 3.3 `ScreenTourUITests` still pass for `testHomeAndDeckOverview` and `testSettings`. If the dialog can be shown with a launch argument (for example `--show-full-sync-choice`), screenshot it and check that the three buttons have equal text size
