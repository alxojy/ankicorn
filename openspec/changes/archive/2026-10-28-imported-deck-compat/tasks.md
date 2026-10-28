## 1. Readable cards
- [x] 1.1 Note CSS keeps priority; a note type with a light `.card` background and no text colour renders dark text on its background (desktop light default); with no background set, the Ink look stays; contrast of default text against its own background is at least 3:1
- [x] 1.2 Desktop night-mode classes are set on the card so decks with their own night styles apply them
- [x] 1.3 Font aliases map faces iOS lacks (Kaiti, SimSun, Gentium Plus, Georgia and similar) to installed equivalents (CJK-capable for CJK faces)

## 2. Media
- [x] 2.1 Find why imported/synced media doesn't load (media folder used by import, open, sync and `MediaSchemeHandler`; whether media sync runs) and fix it; write the cause in the ledger finish entry
- [x] 2.2 Missing images show a small Ink "Image missing" placeholder instead of WebKit's "?" icon
- [x] 2.3 Replay and Speak play the note's sound when it exists, and fall back to TTS of the headword when it doesn't

## 3. Extras on any note type
- [x] 3.1 Headword derivation for foreign note types (first mostly-hanzi field, else first field; HTML, sound tags and cloze stripped); Speak says only the headword
- [x] 3.2 Explain, Translate and stroke order use the card's own text and work on the fixture note types

## 4. Proof
- [x] 4.1 Seed fixtures (invented content): a shared-deck-style note type as described in the proposal (light background, no colour, dotted field names, `[sound:]` and `<img>` fields, no `{{FrontSide}}`, tiny generated jpg and mp3), and one with a dark background and light text
- [x] 4.2 Unit tests: the contrast decision for light/dark/unset backgrounds; headword derivation on the fixture fields; Speak falls back to TTS when the sound file is missing
- [x] 4.3 A test that imports an `.apkg` built at test time from the fixture (with its media) and finds the media files where `MediaSchemeHandler` serves them
- [x] 4.4 A UI test reviewing the fixture card: question and answer screenshots show dark text on the light card and the image loaded; with the image file removed, the placeholder shows. Review the screenshots against the user's broken screenshot
- [x] 4.5 `ScreenTourUITests` still pass; our own Chinese note type still looks the same
