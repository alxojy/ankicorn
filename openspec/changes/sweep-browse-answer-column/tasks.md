## 1. Template
- [ ] 1.1 Both Chinese vocab answer templates use `<hr id="answer" class="rule">`, with the question side above it and the answer side below
- [ ] 1.2 Block elements are separated so the engine's answer column keeps separators between sentence, pinyin and English

## 2. Proof
- [ ] 2.1 A unit test renders a sample note's two cards through the engine and checks the browser `answer` column: it doesn't start with the question text, and "Míngtiān zàijiàn!" is not glued to "See you"
- [ ] 2.2 `ScreenTourUITests` `testBrowse` and `testReviewFlow` pass. Review 30-browse (no repeated question) and 11-review-answer (still matches the mockup)
