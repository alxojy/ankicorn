## 1. Fix
- [x] 1.1 Closed select: one line, vertically centred, chevron centred right, 44 pt, Ink control, radius 12, truncating name; Save split button the same height
- [x] 1.2 Open list: Ink raised surface, radius 14, shadow, select width, above content, 44 pt rows, accent ✓ for the selected row (no blue fill, no left bar), scrolls when long
- [ ] 1.5 Section headers: title and ? on one row, ? vertically centred on the title, Ink section-title size, muted ? icon with a 44 pt target
- [x] 1.3 Same styling for every `Select` on the hosted pages
- [x] 1.4 If CSS can't place the popover correctly in WKWebView, use the native preset header fallback; record the route taken in the ledger

## 2. Proof
- [ ] 2.1 A UI test opens Deck options, screenshots the closed header, taps the preset select, screenshots the open list; asserts the Save button and the select have equal heights (±2 pt). Review both screenshots at iPhone 17 and 320 pt width
- [ ] 2.3 In the same test, assert the "Daily Limits" title's and its help button's vertical centres differ by under 2 pt (web elements via accessibility); review the section header in the screenshot
- [ ] 2.2 Review a second dropdown on the page (new card gather order) open and closed
