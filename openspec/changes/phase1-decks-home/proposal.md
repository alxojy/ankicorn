# Proposal

## Why

The Decks tab still shows the raw Phase 0 deck list. PLAN.md specifies the real home screen: due-count hero, new/learning/review bar, Start review pill and a deck tile grid with a deck overview.

## What Changes

- Decks home: date and quiet sync status (placeholder until Phase 2), round Sync and Add buttons (stubs), 96 pt due-count hero with a time/done/streak line, stacked new/learning/review bar with legend, "Start review" pill.
- 2-column deck tile grid (glyph, name, word count, coloured counts, progress bar); subdecks open a nested grid; collapse state is stored through `set_deck_collapsed`.
- Deck overview screen with `counts_for_deck_today` and a Study button (stub until the review phase).
- Designed loading, empty and error states.
- Backend wrappers: `countsForDeckToday`, `studiedToday`, `setDeckCollapsed`.

Out of scope: real sync, add-card, the review session, streak (placeholder).

## Capabilities

### New Capabilities
- `decks-home`: the Decks home tab and deck overview.

## Impact

PLAN.md "Screens > Decks (home tab)". New files under `app/Cornhub/Screens/DeckHome/`, wrappers in `app/Cornhub/Backend/`.
