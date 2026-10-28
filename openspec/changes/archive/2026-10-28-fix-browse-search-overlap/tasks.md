## 1. Fix
- [x] 1.1 Browse search sits at the top (navigation bar drawer, always shown), not at the bottom
- [x] 1.2 Audit the tab screens: nothing system-placed sits under the floating tab bar

## 2. Proof
- [x] 2.1 `ScreenTourUITests.testBrowse` asserts that the search field's frame doesn't intersect the tab bar's frame (give the tab bar an accessibility identifier if needed), types a query, and checks the results filter. Review the 30-browse screenshot
