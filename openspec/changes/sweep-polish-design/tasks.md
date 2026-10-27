## 1. Design
- [ ] 1.1 Display font on due count, retention, screen titles, card English answer, count rows and grade stamp
- [ ] 1.2 Review: next card peeks behind, grade bar is a floating dark glass capsule
- [ ] 1.3 Add card: Auto-fill not clipped with the keyboard up
- [ ] 1.4 Browse rows: one clean secondary line

## 2. Engine and build
- [ ] 2.1 Find duplicates uses the engine (dupe search), not Swift grouping
- [ ] 2.2 `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64` in project.yml, project regenerated; plain `xcodebuild build` works without extra arch flags

## 3. Proof
- [ ] 3.1 ScreenTourUITests testHomeAndDeckOverview, testReviewFlow, testAddCard and testBrowse pass; screenshots reviewed against PLAN.md and listed in the report
