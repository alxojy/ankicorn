## 1. Build
- [x] 1.1 Role guesser from field names and current template references (unit-tested on the HSK+ field list and on the bundled Chinese vocab note type)
- [x] 1.2 Mapping sheet (Ink): one row per role with a field picker, "not shown on the card" list, "Show example on the front" toggle, preview before/after
- [x] 1.3 Template + CSS generator for the layout in PLAN.md › Review; keeps audio tags; old templates and CSS kept in comments
- [x] 1.4 Apply via `updateNotetype`; engine undo; "Restore original layout"; "Sync to update desktop" prompt
- [x] 1.5 Entry next to "Use Cornhub style" in Settings › Note types, only for note types with a hanzi-like field

## 2. Proof
- [ ] 2.1 Unit tests: guesser on the HSK+ field names; generated templates reference only existing fields; field list and note content unchanged after apply through the engine; restore gives back the exact old templates and CSS
- [ ] 2.2 UI test with an invented note type shaped like HSK+ (invented content and a fixture picture only): apply the layout, screenshot question and answer, compare with the README mockup's Review screen
