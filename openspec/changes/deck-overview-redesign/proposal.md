## Why
The user finds the deck screen experience poor and drew a redesign (two phone mockups, 2026-10-28): a parent deck ("Mandarin (HSK)") and a leaf deck ("HSK1"). They asked to check it against desktop Anki and to spec it with the agreed tweaks. It replaces the layout from `deck-overview-simplify` (merged 29a8ebb, build-only, not archived).

How desktop Anki does it (checked for this spec):
- **Deck list:** a tree with New / Learn / Due columns per deck. The parent mockup's "Levels" list is that, plus progress bars.
- **Deck overview (after clicking a deck):** deck name, today's New / Learning / To Review counts, a Study Now button, the deck description if set, and Options and Custom Study buttons, plus Unbury when cards are buried.
- Desktop has no maturity, forecast or "last studied" on the overview; it keeps those in Stats. Showing them here is an addition. All of them come from the engine.

## What Changes
One screen for every deck. The sections appear only when they apply.
- **Header:** back button; the parent path as a small tappable breadcrumb ("Mandarin (HSK) ›", opens that deck) above the deck's own name with its level icon; the ⋯ menu (Rename, New subdeck…, Delete, Unbury when cards are buried). A top-level deck shows "1,201 cards · 4 levels" (card count and subdeck count) under its name instead of a breadcrumb.
- **Deck description** (when set), short, under the header; "More" expands long ones.
- **Collection card (leaf decks and parents):** total cards ("150 cards"), a two-part bar Mature / Young (unseen in a third, muted segment), the legend with counts, "All seen" when no new cards remain (otherwise "N new"), and "Last studied 2 days ago" (or "Not studied yet"). Counts come from engine searches (`deck:"…" prop:ivl>=21`, `is:new` etc.) and the last review from the engine's stats; nothing is computed by hand in Swift.
- **Today:** three tiles New / Learning / Due with the engine's counts for today (limits applied, as desktop). When a limit holds counts back, the tile gets a muted second line ("limit reached", "of 538 · capped"); tapping it opens a short sheet that explains the limit and links to Daily limits & options. A parent's Today card is titled "Today, across all levels" with "Daily limits on" on the right.
- **Study button:** full-width accent, "Study HSK1 · 148 cards" (parent: "Study all · 575 cards"; the number is the engine's new + learning + due). With nothing due it reads "Nothing due today", is disabled, and Custom study is the row right below.
- **Levels (only when the deck has subdecks):** a list with a header "LEVELS" and the New / Learn / Due column labels; each row has the level icon, name, a seen bar ("150 / 150 seen"), the three counts in their colours, and a chevron that opens that subdeck's screen (same screen, so any depth works).
- **Coming up (leaf decks, or any deck with reviews due):** the engine's forecast for the next 7 days as bars (tomorrow highlighted), "Tomorrow 12" and "Next 7 days 96". Tapping opens Stats filtered to this deck.
- **Rows:** Browse cards (with the card count), Custom study (desktop has it on the overview), Daily limits & options.
- **Ink:** tokens only; the card and tile radii, spacing and type from PLAN.md design standards; Dynamic Type and VoiceOver labels on every tile and bar.
- **Replaces** `deck-overview-simplify`'s "Simple deck screen" requirement; its one counts line, single Study button and ⋯ menu ideas carry over.

## Impact
`Screens/DeckHome/DeckOverviewScreen.swift` (rewrite), `DeckHomeModel.swift` (counts and maturity via engine searches, forecast and last-studied via the engine stats calls `StatsModel` already uses), new small views (Today tile, Levels row, Coming up), launch args for seeded parent/leaf fixtures, tests.
