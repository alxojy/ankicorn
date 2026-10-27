## Why
The final sweep (screen tour on the seeded sample, 45 new cards in HSK 1) found that review cannot be used:
- "Start review" opens straight to "All done for now". `ReviewTarget(deckID: nil)` makes `ReviewModel.start()` skip `set_current_deck`, so the engine queues from its current deck, the empty "Default" deck.
- The deck overview shows 0 new / 0 learning / 0 review for HSK 1 while the home tile shows 45 new. `DeckOverviewScreen` uses `counts_for_deck_today`, which returns cards *studied* today, not cards due.
- The home hero line shows the engine's raw `studied_today` sentence ("Studied 0 cards in 0 seconds today (0s/card)") instead of the PLAN.md line (estimated time · cards done today · streak).

## What Changes
- Start review studies every deck that has due cards: pick the first top-level deck with due cards from `deck_tree` (with `now`), set it current, and when its queue empties continue with the next deck that still has due cards before showing congrats.
- The deck overview takes its new/learning/review numbers from the deck's `deck_tree` node (the same source as the tile).
- The hero line is "≈ N min · X done today · streak —". X comes from the engine (`studied_today` or graphs/today stats), not computed scheduling.

## Impact
`app/Cornhub/Screens/Review/ReviewModel.swift`, `ReviewTarget.swift`, `Screens/DeckHome/DeckOverviewScreen.swift`, `DeckHomeScreen.swift`/`DeckHomeModel.swift`.
