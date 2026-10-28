## Why
Feedback from using the app on the user's iPhone:
- **Speak reads everything.** `ExtrasModel.speak()` reads all of the answer text (hanzi, then pinyin, then English, then the example). The user only wants the word pronounced. PLAN.md and the Ink mockup treat this as the pronunciation button beside the hanzi: deck audio first, then TTS of the word.
- **The greyed-out grade bar on the question side looks bad.** Before the answer shows, the four grade buttons sit there dimmed and disabled. PLAN.md only says "tap anywhere on the card to reveal the answer"; the mockup draws only the answer side.

## What Changes
- **Speak says only the word.**
  - If the note has audio (an Audio field with `[sound:…]`, or a sound tag on the card), play that.
  - Otherwise use TTS on just the headword. For the Chinese vocab note type, that's the **Hanzi** field. For other note types, it's the first field, or the question text with HTML, sound tags and furigana or pinyin stripped. For a Chinese speech language, keep only the hanzi runs (`CardText.hanzi`).
  - Never read pinyin, English or the example sentence.
  - Speak works on both sides of the card.
- **Question side: a "Show answer" capsule instead of dimmed grades.**
  - Before the answer shows, the grade bar's slot holds one floating glass capsule with the same frame, material, border and shadow as the grade bar. It is labelled "Show answer" (or "Tap to reveal"), `text` on glass, 44 pt or taller, VoiceOver label "Show answer".
  - Tapping it or the card reveals the answer. The capsule then turns into the four grade buttons with a short spring (a crossfade with Reduce Motion), and the reveal haptic fires.
  - No disabled or dimmed grade buttons are ever shown. The swipe hint shows only on the answer side, as now.
  - Type-in-the-answer cards keep their existing check flow above the capsule.

## Impact
`app/Cornhub/Extras/ExtrasModel.swift`, `CardText.swift`, `Screens/Review/ReviewScreen.swift`, `ReviewModel.swift` (if the headword or audio needs exposing), and `ScreenTourUITests.testReviewFlow`.
