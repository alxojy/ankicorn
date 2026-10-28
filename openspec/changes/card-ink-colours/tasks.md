## 1. Fix
- [ ] 1.1 Document CSS: the note type's `background`/`background-color`/`background-image` on `html`, `body`, `.card` (and `.nightMode` variants) are overridden so only the Ink `card` colour shows; the cream case renders like `.ink`
- [ ] 1.2 Default text is the Ink `text` token
- [ ] 1.3 In-page contrast pass after load and reveal: for each text element whose computed colour is below AA against the `card` token, greys/near-black become `text`/`muted`, coloured text is lightened in the same hue until it passes
- [ ] 1.4 Remove `card-always-dark`'s invert/hue-rotate rendering, media re-inversion and the Card colours setting; no CSS filter anywhere; pictures untouched
- [ ] 1.5 Remove the review ⋯ "Restyle this note type…" prompt for light note types (Settings › Note types keeps "Use Cornhub style")

## 2. Proof
- [ ] 2.1 Unit tests on the document: the cream note type CSS yields no visible cream (override present), no `filter`, the Ink text default; `.ink` and `.dark` documents unchanged; replace `CardColoursTests` accordingly
- [ ] 2.2 UI test with the invented cream note type fixture (as in `imported-deck-compat`, invented content only): screenshot of question and answer; the pinyin is green and passes AA (read the computed colour through the page); the note type CSS read back from the engine is unchanged
