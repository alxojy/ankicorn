## Why
The user can't delete (or rename) a deck in the app; today the only way is desktop Anki plus a sync. PLAN.md's parity table never listed deck management, so it was missed. The engine already has `remove_decks`, `rename_deck` and `reparent_decks` (DecksService methods 16–18, already in `ServiceIndex.swift`), and they are undoable.

## What Changes
- **Deck tile actions:** a long press on a deck tile (Home grid and subdeck grids) opens a context menu with **Rename**, **Delete** and **Options** (opens the existing deck options page). The deck overview screen's ⋯ / toolbar gets the same actions.
- **Rename:** an alert with a text field, prefilled with the deck's full name. `::` makes a subdeck, as in Anki; the engine validates it. Calls `rename_deck`. Errors such as a duplicate name show the engine's message.
- **Delete:** a confirmation dialog: "Delete "HSK 2"?", with the message "Its N cards and any subdecks will be deleted. You can undo this right away." The button is "Delete Deck" (destructive) plus Cancel. Calls `remove_decks` with the deck id. The card count comes from the deck tree node (including subdecks).
- After deleting, the grid refreshes and a short undo toast ("Deleted HSK 2 · Undo") shows for a few seconds. Undo calls the engine's `undo`, the same backend undo that review uses, and refreshes.
- The **Default** deck (id 1) can't be deleted, as in Anki. It isn't offered, or the engine's refusal is shown. Filtered decks can be deleted too; their cards go back home (engine behaviour).
- Wrap `removeDecks(ids:)`, `renameDeck(id:name:)` in `Backend+Decks.swift` (typed wrappers, no logic in Swift).
- Accessibility: the same actions are available as VoiceOver custom actions on the tile.

## Impact
`app/Cornhub/Backend/Backend+Decks.swift`, `Screens/DeckHome/DeckHomeScreen.swift`, `DeckTileView.swift`, `DeckHomeModel.swift`, `DeckOverviewScreen.swift`, plus unit and UI tests.
