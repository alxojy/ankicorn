## 1. Fixes
- [x] 1.1 Start review (no deck) chooses decks with due cards from `deck_tree` and moves on to the next one before congrats
- [x] 1.2 Deck overview counts come from the deck's `deck_tree` node
- [x] 1.3 Home hero line: "≈ N min · X done today · streak —" (no raw engine sentence)

## 2. Proof (sweep: tests are required again for fixes)
- [x] 2.1 `xcodebuild test -only-testing:CornhubUITests/ScreenTourUITests/testReviewFlow` passes and its screenshots show a question, an answer with the grade bar and intervals, and the next card
- [x] 2.2 `testHomeAndDeckOverview` passes and the overview screenshot shows 45 new for HSK 1
