## 1. Fix
- [ ] 1.1 Setting `Card colours` (App default / Note type's own) in the settings store and Settings › Review (Ink row, 44 pt)
- [ ] 1.2 App mode + `.light`: Ink card background behind the content, content inverted with hue kept, media (`img`, `video`, `canvas`, `svg image`, `[style*=background-image]`) inverted back
- [ ] 1.3 Contrast floor for coloured text after inversion (AA against the Ink card colour)
- [ ] 1.4 Note type's own mode keeps today's `.light` rendering; `.ink` and `.dark` unchanged in both modes
- [ ] 1.5 In App mode, drop the review ⋯ "Restyle this note type…" prompt for light note types (keep it in Settings › Note types)

## 2. Proof
- [ ] 2.1 Unit tests on the document CSS: App + light includes the inversion and the media re-inversion; Note type's own + light doesn't; ink and dark unchanged in both modes
- [ ] 2.2 UI test with the invented cream note type fixture (as in `imported-deck-compat`): screenshot in App mode (dark card, green pinyin, picture in real colours) and in Note type's own mode; the note type CSS read back from the engine is unchanged
