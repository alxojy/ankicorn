## Why
The user wants their imported HSK cards to look like the README mockup's Review screen, not just dark. Today an imported note type keeps its own template, so the card is laid out like desktop: a 78px Kaiti headword on the left, pinyin and meaning stacked under it, the sentence, then the picture last (and cut off on small screens). PLAN.md › Review describes the target layout and says imported HSK decks should be able to get it.

The user's note type is "HSK+". Its back template (observed in their collection, read-only) uses the fields `Simplified`, `Homograph`, `Pinyin.1`, `Meaning`, `Part of speech`, `SentenceSimplified`, `SentencePinyin.1`, `SentenceMeaning`, `Audio`, `SentenceAudio`, `SentenceImage` (it has 19 fields in all). The front shows `Simplified`, `Homograph` and `SentenceSimplified`.

Editing a template's HTML and the CSS is a normal (incremental) sync change; it doesn't add or remove fields or templates, so no full sync is needed.

## What Changes
- **"Use Cornhub layout"** next to "Use Cornhub style" in Settings › Note types › (note type), for note types with a hanzi-like field. It rewrites the note type's card templates (front and back of each existing template) and CSS to the mockup layout, using the note type's own fields. No fields are added, removed or renamed, and no note content changes.
- **Field mapping sheet:** the app guesses each role from field names and the current templates, and the user can change any of them before applying:
  - Hanzi (`Simplified`), Pinyin (`Pinyin.1`/`Pinyin`), Meaning (`Meaning`/`English`), Part of speech, Picture (`SentenceImage`/`Image`/`Picture`), Example (`SentenceSimplified`), Example pinyin (`SentencePinyin.1`), Example meaning (`SentenceMeaning`), Audio (`Audio`, `SentenceAudio`), Extra (`Homograph`).
  - Fields that get no role are listed as "not shown on the card" so nothing disappears silently.
- **The layout (PLAN.md › Review):**
  - Back: picture at the top (rounded, about 130 pt, no gap when empty), hanzi large with pinyin in accent beside it, a hairline, the meaning in the display font with the part of speech muted, the example sentence with the headword highlighted in accent, then its pinyin and meaning muted. Audio tags stay so replay and Speak keep working.
  - Front: the hanzi only (with Extra if mapped), centred, as in the mockup's question side. Keep the user's existing front choice of also showing the example sentence only if they tick "Show example on the front".
  - CSS: no background, Ink roles in the app (`.nightMode`), desktop-safe light colours otherwise, as in `notetype-app-style`.
- **Safe to undo:** preview of a real card before and after; apply through the engine's `update_notetype`; engine undo works; the old templates and CSS are kept (CSS comment block plus the old template text in a comment inside each template) and "Restore original layout" puts them back.
- **Desktop:** after applying, "Sync to update desktop" with Sync now; desktop shows the same layout.

## Impact
`Backend/Backend+Manage.swift` (`getNotetype`/`updateNotetype`), a new template generator next to `NotetypeStyle`, the note type settings screen and a mapping sheet, tests. Engine does storage, undo and sync; Swift only builds template and CSS strings.
