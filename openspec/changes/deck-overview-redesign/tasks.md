## 1. Build
- [x] 1.1 Model: per-deck total, mature (`prop:ivl>=21`), young, new counts via engine searches; last studied and 7-day forecast via the engine stats calls `StatsModel` uses; today's counts and whether limits capped them from the deck tree / engine (uncapped due via `is:due` search)
- [x] 1.2 Header with tappable breadcrumb, level icon and ⋯ menu (Rename, New subdeck…, Delete, Unbury when buried); top-level subtitle "N cards · M levels"; description with More
- [x] 1.3 Collection card (total, Mature/Young/New bar and legend, All seen / N new, Last studied)
- [x] 1.4 Today tiles with capped/limit-reached second line and the explanation sheet linking to Daily limits & options; parent title "Today, across all levels" + "Daily limits on"
- [x] 1.5 Study button ("Study X · N cards", "Study all · N cards", disabled "Nothing due today")
- [x] 1.6 Levels list (only with subdecks): icon, name, seen bar, coloured counts, chevron to the same screen for that deck
- [x] 1.7 Coming up (7-day bars, tomorrow highlighted, totals), tap opens Stats filtered to this deck
- [x] 1.8 Rows: Browse cards (count), Custom study, Daily limits & options
- [x] 1.9 Remove the `deck-overview-simplify` layout; when archiving, drop its "Simple deck screen" requirement from the decks-home spec

## 2. Proof
- [ ] 2.1 Unit tests on the model with invented seeded decks: mature/young/new counts, capped detection, Study total equals new + learning + due from the engine, Levels only for decks with children
- [ ] 2.2 UI test: open the seeded parent deck and a leaf subdeck; screenshots of both (compare with the user's mockups), tap the breadcrumb back to the parent, tap a level row, open the capped explanation, Nothing due state at 320 pt width and at large Dynamic Type
