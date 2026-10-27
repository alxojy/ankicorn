## 1. Fixes
- [ ] 1.1 The grade bar never breaks a label mid-word at any Dynamic Type size; buttons are at least 44 pt
- [ ] 1.2 The review header buttons don't collide at accessibility sizes
- [ ] 1.3 The review card shows its content at the largest accessibility size
- [ ] 1.4 The home New/Learning/Review legend wraps whole items at accessibility sizes
- [ ] 1.5 Custom study pluralises "card"; the login sheet explanation wraps fully
- [ ] 1.6 Add card with the keyboard up: the last field (Back Extra) is not hidden behind the Auto-fill button; the field list scrolls clear of the pinned buttons

## 2. Proof
- [ ] 2.1 `ScreenTourUITests` `testLargestTextSize` (extend it to wait for the card text before 61-review-xxxl), `testHomeAndDeckOverview` and `testSettings` pass. Review 60-home-xxxl, 61-review-xxxl, 05-custom-study and 55-login
