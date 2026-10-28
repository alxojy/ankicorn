## 1. Restyle
- [ ] 1.1 `NotetypeStyle` builds Ink CSS from a note type's CSS and templates: no `.card` background, Ink roles in `.nightMode`/`.night_mode`, desktop-safe light-mode rules, headword/pinyin/meaning/sentence classes mapped as in the proposal, old CSS kept in a `/* cornhub: previous css */` comment
- [ ] 1.2 Settings › Note types › (type) › "Use Cornhub style" with a before/after preview of a real card of that type; apply through `updateNotetype`; engine undo works; "Restore original style" when the comment is present
- [ ] 1.3 The review ⋯ menu offers "Restyle this note type…" when the current note type sets its own `.card` background
- [ ] 1.4 After applying: "Sync to update desktop" with Sync now; no automatic sync

## 2. Proof
- [ ] 2.1 Unit tests on `NotetypeStyle` with the imported-deck fixture CSS (the HSK+ shape): no background on `.card`, night-mode rules present, class names kept, old CSS recoverable, generating twice is stable
- [ ] 2.2 A unit test through the engine: apply to the fixture note type, the card renders with the new CSS, undo restores the old CSS, restore from comment works
- [ ] 2.3 A UI test: open the fixture card, ⋯ › Restyle, preview, apply; screenshots before and after show the Ink look (dark card, light text, display headword)
