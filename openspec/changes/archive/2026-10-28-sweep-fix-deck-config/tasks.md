## 1. Fixes
- [x] 1.1 `addDeck` uses the engine's `new_deck` template (config_id from the engine)
- [x] 1.2 Existing broken decks are repaired through the engine (`check_database`) on open
- [x] 1.3 Other hand-built new objects checked against the engine's `new_*`/defaults methods

## 2. Proof
- [x] 2.1 A unit test in `app/CornhubTests/` adds a deck through `Backend.addDeck` and asserts its `normal.configID` is a real preset (`get_deck_config` succeeds)
- [x] 2.2 `ScreenTourUITests/testReviewFlow` passes, and the Card info screenshot shows card statistics, not the inconsistent-database error (tap Done to close the sheet)
