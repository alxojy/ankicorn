## Why
The user imported their own deck from desktop Anki and the review screen broke (screenshot: the 也许 card):
- **Most text is invisible.** The headword, meaning, sentence and translation render as near-white text on a cream box. Only text with its own colour (green pinyin, grey part of speech, the bold word) shows.
- **A broken-image "?" icon** where the sentence picture should be.
- **Speak (and the other extras) do nothing.**

The orchestrator read the deck's note type from a copy of the desktop collection (read-only; nothing is committed). It is a common shared-deck shape, so the causes apply to many decks:

- **Note type "HSK+"**, 19 fields: `Key, Simplified, Traditional, Pinyin.1, Pinyin.2, Meaning, Part of speech, Audio, Homophone, Homograph, SentenceSimplified, SentenceTraditional, SentenceSimplifiedCloze, SentenceTraditionalCloze, SentencePinyin.1, SentencePinyin.2, SentenceMeaning, SentenceAudio, SentenceImage`. One card type, "Recognition". The answer doesn't use `{{FrontSide}}`.
- **Its CSS:**
  ```css
  .card {font-family: arial; font-size: 10px; text-align: left; #222222; background-color: #fdf6e3;}
  .hanzi {font-family: Kaiti; font-size: 78px;}
  .pinyin {font-family: Gentium Plus; font-size: 22px; color: #005500;}
  .english, .meaningSent, .description {font-family: Georgia; font-size: 16px;}   /* description: color #575757 */
  .sentence {font-family: SimSun; font-size: 24px;}
  ```
  The deck sets a light `.card` background but **no text colour** (the `#222222;` is missing `color:`, so browsers drop it). Desktop renders it dark-on-cream because the default text colour in light mode is dark.
- **Fields hold media:** `Audio` = `[sound:ye3xu3.mp3]`, `SentenceAudio` = `[sound:…mp3]`, `SentenceImage` = `<img src="el2k4190kkn2o.jpg">`. The desktop media folder has 7,149 mp3 and 871 jpg files.

Causes in our code:
1. **Text colour.** `CardWebView.baseCSS` sets `body` and `.card` `color` to `Theme.text` (light, for the Ink dark card) before the note's CSS. A note type that sets a light background but no colour inherits our light text: white on cream.
2. **Media.** The `<img>` fails (WebKit's "?" icon), and Speak prefers the note's audio (`SpeechTarget.audio`), which plays nothing. So the media files are either not in the folder `MediaSchemeHandler` serves (`Documents/collection.media`), or the import or sync didn't bring them. To be found: how the deck got in (`.apkg` import, `.colpkg`, or full sync download), whether its media landed, and whether the media sync ran. Also, when the note's audio is missing, Speak must fall back to TTS of the word, not fail silently.
3. **Extras assume our own note type.** Speak's text, Explain, Translate and stroke order use the rendered question/answer text or our Chinese note type's fields. For a foreign note type they must still pick something sensible: Speak says the main headword (the first field whose text is mostly hanzi, or the question's main text), not the whole card.
4. **Fonts.** Kaiti, SimSun, Gentium Plus and Georgia aren't all on iOS. The fallback should be a CJK-capable face (Kaiti → `Kaiti SC`/`STKaiti` if present, otherwise `PingFang SC`), not a missing glyph or Times.

## What Changes
- **Deck styling wins, with readable defaults.** The note's CSS keeps priority, as on desktop. After the card renders, measure the effective `.card` background. If the note type sets an opaque light background, render the card in light mode: default text dark (desktop's light default, `#000`/`#222`), the card's box keeping the deck's background, and no Ink text colour. If the note sets nothing, keep the Ink look. Never produce text with less than 3:1 contrast against its own background just because of our defaults. Night-mode classes (`.nightMode`, `.night_mode`) are set as on desktop, so decks with their own night styles use them.
- **Media works for imported decks.**
  - Find and fix why images and sounds don't load (check the import path's media folder against `MediaSchemeHandler.mediaFolder` and `openCollection`'s, and that the media sync runs after a sync).
  - Missing media shows a small Ink placeholder ("Image missing"), not WebKit's broken "?" icon.
  - The ▶︎ replay button and Speak play the note's sound when the file exists, and otherwise fall back to TTS of the headword.
- **Extras work on any note type.** Speak, Explain, Translate and stroke order derive their input from the card itself:
  - the headword: the first non-empty field that is mostly hanzi (or the first field), with HTML, sound tags and cloze markup stripped;
  - the question and answer text from the rendered card.

  Our own Chinese note type keeps its explicit fields.
- **Font fallback** for common CJK and Western faces that iOS lacks, through a small `@font-face`/`font-family` alias block in the base CSS, so Kaiti, SimSun and friends map to the iOS equivalents.
- **Compatibility fixtures.** Add an invented shared-deck-style note type to the test seed. It mirrors this shape: a light `.card` background with no colour, many fields with dotted names, `[sound:]` and `<img>` fields, a template without `{{FrontSide}}`, and a tiny generated jpg and mp3 under invented names. Also add one with a dark `.card` background and light text. No real user data or real deck files go in the repo.

## Impact
`Screens/Review/CardWebView.swift` (base CSS, contrast, fonts, missing-media placeholder), `MediaScheme.swift`, `CardAudio.swift`, `ReviewModel.swift` (speech target), `Extras/ExtrasModel.swift`, the import and sync paths for media (`Backend+Import.swift`, `SyncModel.swift`), `Backend/SampleNotes.swift` (fixtures), and tests. High priority: the user can't study their real deck. Run next after the current worker.
