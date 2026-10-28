## 1. Home matches the mockup
- [x] 1.1 Header: small date and status, exactly two 44 pt bordered round buttons (Sync, Add card); "Import deck" moves to Settings › Import and export
- [x] 1.2 Hero: count and "cards due" on one baseline row; subline "About N min · X done today · N-day streak" with the real streak
- [x] 1.3 Due bar always visible (an empty track at 0) and a count-first lower-case legend
- [x] 1.4 Start review 60 pt pill with a trailing arrow; 20 pt section spacing
- [x] 1.5 "Decks" heading display 22; deck tiles match design.md (glyph font and colour cycle, sizes, border, progress bar)
- [x] 1.6 Tab bar matches design.md (64 pt capsule, 10 pt labels)

## 2. Proof
- [x] 2.1 A unit test for the shared streak helper (0 days, a run ending today, a run broken yesterday)
- [x] 2.2 `ScreenTourUITests` `testHomeAndDeckOverview`, `testLargestTextSize` and `testSettings` pass (update them for the moved import button). Put 01-home next to design.md and list each item in 1.1–1.6 as matching or not
