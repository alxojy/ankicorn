## Why
Demo mode left the app with almost no UI tests. The two Phase 0 `DeckTreeUITests` now fail, because the deck list moved into the tab shell. The orchestrator's sweep added `ScreenTourUITests`, which walks every tab and the main flows with screenshots. It must become the regression suite, so `ANKICORN_FULL=1 npm run gate` can go green.

## What Changes
- Remove the obsolete `DeckTreeUITests`, the unused `DeckTree` screen and model, and their unit tests.
- Make `ScreenTourUITests` robust: scroll to the Settings rows before tapping, open Browse rows by tapping the row element, dismiss sheets with their Done/close buttons instead of swipes, and assert visible results on each screen.
- Fix any real bugs the tour exposes along the way, keeping each fix small, or report them.

## Impact
`app/CornhubUITests/*`, `app/CornhubTests/DeckTreeModelTests.swift`, `app/Cornhub/Screens/DeckTree/`.
