## 1. Card
- [ ] 1.1 Missing images are removed from the layout with no placeholder; trailing blank space they leave is trimmed; remove the "Image missing" placeholder
- [ ] 1.2 The note-audio replay button sits in the app chrome (frame corner or extras row), never over the card's HTML

## 2. Translate and extras panel
- [ ] 2.1 Translate detects the source language from the card text (hanzi → zh-Hans), targets the device language, short-circuits same-language, and shows a friendly line when the pair isn't available; never the raw error
- [ ] 2.2 The extras result panel and its error lines use Ink tokens (surface, radius, muted text, SF Symbol)

## 3. Proof
- [ ] 3.1 Unit tests: language detection on Chinese, English and mixed card text; same-language short-circuit; unavailable-pair message mapping
- [ ] 3.2 A UI test on the imported-deck fixture with the image file removed: no "Image missing" text and no image element visible; the replay button's frame doesn't intersect the card web view's frame. Review the answer screenshot
