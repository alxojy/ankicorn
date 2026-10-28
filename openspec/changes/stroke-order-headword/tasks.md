## 1. Fix
- [ ] 1.1 `showStrokes` uses the hanzi of `CardText.headword(...)`, in order, deduplicated; the Stroke order button is hidden when the headword has no hanzi
- [ ] 1.2 Strokes panel: one row (up to 4 per row at a fitting size, horizontal scroll beyond), nothing clipped, height from content; tap a character to replay; attribution kept

## 2. Proof
- [ ] 2.1 Unit tests: the imported-deck fixture (headword plus a sentence with other hanzi) gives only the headword's characters; repeated characters appear once; no hanzi hides the button
- [ ] 2.2 A UI test on the fixture card: open Stroke order, exactly the headword's character count of stroke views exist and each lies fully inside the panel. Review the screenshot
