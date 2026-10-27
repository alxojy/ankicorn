## Why
Phase 3 needs finding and bulk-editing cards on the phone. PLAN.md parity rows "Browser: search, sortable columns, sidebar", "Browser actions" and "Previewer".

## What Changes
- Browse tab: searchable list (`search_cards` / `search_notes`, rows from `browser_row_for_id`, columns from `all_browser_columns`), sort by column, cards/notes toggle.
- Filter sheet listing decks, tags, note types and flags; choosing one composes a search.
- Row tap opens the note editor; a preview button shows the card in `CardWebView`.
- Multi-select actions: change deck, add/remove tags, reposition, set due date, forget (reset to new), suspend, delete.
- Backend wrappers for the search, tag, deck and scheduling methods above.
