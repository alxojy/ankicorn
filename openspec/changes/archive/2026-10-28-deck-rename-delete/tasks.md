## 1. Engine wrappers
- [x] 1.1 `Backend.removeDecks(ids:)` returns the removed card count; `Backend.renameDeck(id:name:)`

## 2. UI
- [x] 2.1 Long-press menu on deck tiles (Rename, Delete, Options), also on the deck overview and as VoiceOver actions
- [x] 2.2 Rename alert with the engine's validation errors shown
- [x] 2.3 Delete confirmation with the card count; Default isn't deletable; after deleting, the grid refreshes and an Undo toast restores the deck

## 3. Proof
- [x] 3.1 Unit tests (`DeckWrapperTests`): rename a deck and read the new name from `deck_tree`; delete a deck with notes and check that `deck_tree` no longer has it and the returned count matches; undo brings it back
- [x] 3.2 A UI test: long-press the HSK 2 tile, Delete, confirm, and the tile is gone; tap Undo in the toast, and the tile is back. Rename HSK 2 to "HSK 2b" and the tile shows the new name. Review the menu, dialog and toast screenshots against the Ink look
