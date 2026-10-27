## 1. Override
- [ ] 1.1 Primary buttons (deck options Save), checked radios, checkboxes and switches, and selected tab underlines use the Ink accent
- [ ] 1.2 Selects and inputs use the Ink control background and text colours
- [ ] 1.3 Headings use the Ink display font (or a documented fallback)

## 2. Proof
- [ ] 2.1 A unit test checks that `inkCSS` contains the accent for the primary button, form-check and switch selectors
- [ ] 2.2 `ScreenTourUITests` `testHomeAndDeckOverview` (04-deck-options-web), `testReviewFlow` (15-card-info-web) and `testStats` (42-more-stats-web) pass. Review the three screenshots: no blue controls remain
