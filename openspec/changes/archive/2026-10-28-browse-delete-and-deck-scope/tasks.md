## 1. Deck scope
- [x] 1.1 A deck chip under search picks the deck (with subdecks); the count line names the deck; the filter sheet stays in sync
- [x] 1.2 The deck overview's "Browse cards" opens Browse scoped to that deck

## 2. Select and delete
- [x] 2.1 While selecting, the action bar (count, Actions, Delete) is fully visible and never under the tab bar; Select all is available
- [x] 2.2 Delete confirms with note and card counts, deletes through the engine, then shows an Undo toast; selection mode ends
- [x] 2.3 Trailing swipe on a row deletes that note (with confirmation)

## 3. Proof
- [x] 3.1 A UI test: choose the HSK 2 deck in the chip and the count line reads "… in HSK 2". Select two rows and tap Delete (assert the button is hittable and its frame doesn't intersect the tab bar), confirm, and the rows are gone and the count drops. Undo brings them back
- [x] 3.2 A UI test: from the HSK 1 overview, "Browse cards" lands on Browse scoped to HSK 1
- [x] 3.3 `ScreenTourUITests.testBrowse` passes. Review the selection-mode and deck-picker screenshots
