## 1. Fix
- [ ] 1.1 On congrats, Undo shows only when undo is available, and ⋯ is hidden when it has no enabled action
- [ ] 1.2 Undo from congrats brings back the last graded card (including in all-decks mode) on the question side
- [ ] 1.3 Disabled header controls use the muted/zero token

## 2. Proof
- [ ] 2.1 A UI test: a launch argument seeds a deck with exactly one due card. Grade it to reach congrats, tap Undo, and assert the card is back (`review-card` exists, congrats is gone). Also reach congrats with nothing graded and assert there's no ⋯ button and no Undo
- [ ] 2.2 `ScreenTourUITests` `testReviewFlow` still passes. Review the congrats screenshot (before and after undo)
