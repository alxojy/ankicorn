## 1. Live search
- [ ] 1.1 Typing in Browse search runs the engine search debounced (~300 ms), cancelling the pending one; submit still searches at once; a late stale result never replaces newer results
- [ ] 1.2 Clearing the field (ⓧ or deleting the text) shows all cards again without submitting

## 2. Tab bar and keyboard
- [ ] 2.1 While the keyboard is up, the floating tab bar is hidden or stays below it, never above it, on every tab; it returns when the keyboard closes. Keep the selection-mode rule from `browse-delete-and-deck-scope`

## 3. Proof
- [ ] 3.1 A unit test on `BrowseModel`: rapid query changes run one search for the final text, and an older search finishing late doesn't overwrite it
- [ ] 3.2 A UI test: type a query without pressing return and the rows filter; clear it and the count returns to the full number
- [ ] 3.3 A UI test: with the Browse search field focused (keyboard up), the tab bar is not hittable or its frame is below the keyboard's top; after dismissing the keyboard it is hittable again. Review the screenshots
