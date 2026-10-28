## Why
User: "there's create new card but no create new deck?" The home screen's top-right **+** opens Add card directly (`DeckHomeScreen`, `roundButton("plus", "Add card")`). There is no way to make a deck in the app. `Backend.addDeck(name:)` exists (engine `new_deck` + `add_deck`), but only the sample-deck seeding calls it.

## What Changes
- **The + button becomes a menu:** "Add card" (first, as now) and "New deck". Long-pressing isn't needed: tapping + opens the menu. Keep VoiceOver labels on both items.
- **New deck sheet:** a small sheet or alert with a name field (auto-focused) and Create / Cancel.
  - **Subdecks:** typing `Parent::Child` makes a subdeck, as in Anki. A hint under the field says so.
  - **Empty names:** whitespace is trimmed, and an empty name disables Create.
  - **Duplicate names:** the engine quietly makes them unique (`deck-rename-delete` found this). Before creating, check the existing deck names, and if the name is taken show "A deck called X already exists" and keep the sheet open.
  - **After creating:** the deck tree refreshes, and the new deck is scrolled into view and briefly highlighted. The undo toast from `deck-rename-delete` offers Undo (engine `undo`).
- **New subdeck from a deck:** the deck screen's ⋯ menu gets "New subdeck…", which opens the same sheet prefilled with `Parent::`.
- **Add card after creating:** if the user opens Add card right after creating a deck, the deck picker defaults to the new deck.
- The engine does the work: `addDeck` only, with no deck logic in Swift beyond trimming the name and the duplicate check against the tree.

## Impact
`Screens/DeckHome/DeckHomeScreen.swift` (the + menu, the sheet), `DeckHomeModel.swift` (create, the duplicate check, last-created deck), `DeckOverviewScreen.swift` (the ⋯ item), the Add card default deck, and tests. Run after `deck-overview-simplify`, which reorganises the deck screen's ⋯ menu.
