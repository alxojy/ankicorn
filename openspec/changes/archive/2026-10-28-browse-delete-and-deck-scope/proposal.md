## Why
User feedback on Browse: "why can't I delete? Browse should be based on deck. Multi-select = delete."

What the code does now:
- **Delete exists but can't be reached.** In Select mode, `BrowseScreen` appends `actionBar` (count, Actions menu, trash) to the bottom of its VStack. The custom `FloatingTabBar` overlay from `AppShell` covers it, the same class of bug as `fix-browse-search-overlap`. Rows also have no swipe-to-delete.
- **Deck scope is hidden.** `BrowseModel.deck` adds a `deck:` search term, but it can only be set from the filter sheet behind the ≡ button. There's no deck picker on the screen, and the deck you were looking at doesn't carry over.

## What Changes
- **Deck scope at the top:** a deck chip under the search field, "All decks ▾", opens a picker of the deck tree (indented subdecks, with card counts) and sets `BrowseModel.deck`. It includes subdecks, as `deck:` does in Anki. The count line reads "45 cards in HSK 1". The filter sheet's deck section stays in sync with the chip.
- **Opening Browse from a deck:** the deck overview gets a "Browse cards" button. It switches to the Browse tab scoped to that deck (shared app state, for example `AppShell`'s selection plus a `browseDeck` value). The last scope is kept while the app runs.
- **Multi-select actions above the tab bar:** while selecting, the floating tab bar hides (slides away) and the action bar takes its place as a floating glass capsule in the same style: count, Actions menu and Delete (trash, destructive). Or the action bar sits above the tab bar and clears it fully; pick one, but nothing may overlap. "Select all" in the navigation bar while selecting.
- **Delete:** the confirmation states what goes: "Delete 3 notes (5 cards)?". In Cards mode, deleting removes the cards' notes, as in Anki; say so in the message. Calls the engine (`remove_notes`) as now. After deleting, an Undo toast appears (engine `undo`), and selection mode ends.
- **Swipe to delete:** a trailing swipe on a row offers Delete (destructive, with the same confirmation for one note).

## Impact
`Screens/Browse/BrowseScreen.swift`, `BrowseModel.swift`, `BrowseSheets.swift`, `Screens/Shell/AppShell.swift`, `FloatingTabBar.swift`, `Screens/DeckHome/DeckOverviewScreen.swift`, and tests. Run after `fix-browse-search-overlap`.
