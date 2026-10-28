## Why
The user's imported deck now renders readably, but it still looks like a desktop deck: a cream box with Kaiti/Georgia/SimSun type inside the dark Ink card (screenshots of 也许, question and answer). They want their existing deck to follow the app's style, and the change must go back to desktop Anki by sync, so it has to be a change to the note type itself, not only an in-app override.

The note type is "HSK+" (recorded in `imported-deck-compat`'s proposal). Its CSS sets `.card { background-color: #fdf6e3; font-family: arial; font-size: 10px; text-align: left; }` plus per-class fonts, sizes and colours (`.hanzi` 78px Kaiti, `.pinyin` 22px green `#005500`, `.english`/`.meaningSent`/`.description` 16px Georgia, `.sentence` 24px SimSun).

Editing a note type's CSS is a normal (incremental) sync change in Anki; only field or template structure changes force a full sync. So the CSS can be rewritten on the phone and a normal Sync carries it to desktop.

## What Changes
- **"Use Cornhub style" for a note type**, in Settings › Note types › (note type), and offered from the review ⋯ menu when the current card's note type sets its own `.card` background ("Restyle this note type…").
  - **Preview:** shows the current card before and after.
  - **Explain the effect:** says it changes how these cards look on every device after sync, including desktop.
  - **Apply:** the engine's `update_notetype` writes the new CSS. Undo works through the engine's undo, and the old CSS is kept in a comment block at the end of the new CSS, `/* cornhub: previous css … */`, so it can be restored later ("Restore original style").
- **The generated CSS** keeps the note type's class names, so templates are untouched, and maps them onto Ink:
  - **No background:** `.card` gets no background colour, so the app draws the Ink card. Text is the Ink text colour in the app and dark on desktop light mode: the CSS uses `.nightMode`/`.night_mode` rules for light-on-dark and plain rules for desktop light mode, so desktop looks right in both modes.
  - **Type scale:** a headword-like class (the one containing the first field, or the largest font size) becomes the display face, large and centred. Pinyin-like classes become the accent colour at body size. Meaning, sentence and description classes become body and secondary text in the system font. Sentences use PingFang-style CJK system fonts. Centre aligned like our own Chinese note type.
  - **Colours:** fixed colours in the old CSS are dropped in favour of the Ink roles (text, muted, accent), with desktop-safe equivalents in light mode.
  - **Images:** keep the standard picture size from `card-image-standard-size`.
- Works for any note type, not just HSK+. The mapping is heuristic; the preview lets the user check before applying.
- Nothing is synced automatically. After applying, the screen says "Sync to update desktop" with a Sync now button (the normal sync, which is incremental).

## Impact
`Backend/Backend+Manage.swift` (existing `getNotetype`/`updateNotetype`), a new `NotetypeStyle` (CSS generator), the note type settings screen, the review ⋯ menu, and tests. Engine does the storage, sync and undo; Swift only builds the CSS string.
