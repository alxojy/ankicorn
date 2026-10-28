## Why
Two problems the user hit on the deck screen (`DeckOverviewScreen`):

1. **"Unbury" does nothing.** The button runs `try? await model.backend?.unburyDeck(id:)` and then `refresh()`:
   - Errors are swallowed.
   - It shows even when the deck has no buried cards, so usually nothing visible happens.
   - It never says what it did.

   The worker must also check whether the call really unburies cards (seed a buried card, unbury, and confirm the counts change). If the counts don't change, find out why (for example the method index, or `mode`).
2. **The deck options header looks broken.** The top of the hosted deck options page is Anki's desktop header: `ts/routes/deck-options/ConfigSelector.svelte`'s `.button-bar`, a preset `<Select>` plus the `SaveButton.svelte` split button.
   - On a phone it runs to the screen edge with no margin.
   - The select and the Save button have different heights.
   - The Save dropdown caret is cut off at the right edge.

   Our CSS only recolours it. Separately, the native **Done** button closes the sheet without saving, so edits are silently lost.

## What Changes
**Unbury**
- Show Unbury only when the deck (with its subdecks) has buried cards: a count from the engine (`search_cards` with `deck:"<name>" is:buried`, or `congrats_info`'s buried flags).
- After unburying, refresh the counts and show a short confirmation ("Unburied N cards"). Show errors.

**Deck options header (CSS injection only; Anki's built pages aren't edited)**
- Lay out `.button-bar` for a phone:
  - 16 pt side padding and safe-area aware;
  - the preset select takes the remaining width, with an Ink control background, radius 12 and a height of 44;
  - the Save split button has the same 44 height, an accent fill with `onAccent` text and an attached chevron segment (the same height, a thin divider);
  - nothing overflows the viewport;
  - the sticky header gets the `bg` background and a hairline bottom border.
- Long preset names truncate with an ellipsis, not by pushing Save off-screen.
- Check at 320 pt width (iPhone SE size) and at the largest text size the page supports.

**Saving**
- Tapping native **Done** with unsaved changes either saves first (by triggering the page's save the way `SaveButton` does, for example by dispatching the Ctrl/Cmd+Enter shortcut it listens for, or by calling the exported save), or asks "Save changes?" with Save / Discard / Cancel. With no changes, Done just closes. Find out from the page's own code how it tracks unsaved changes.

## Impact
`Screens/DeckHome/DeckOverviewScreen.swift`, `DeckHomeModel.swift`, maybe `Backend+CardActions.swift`, `Web/AnkiWebView.swift` (CSS and the save hook), and tests.
