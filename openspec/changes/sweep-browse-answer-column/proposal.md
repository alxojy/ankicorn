## Why
In the final sweep, the second line of Browse rows (cards mode) repeats the question and runs fields together, for example "你好nǐ hǎo · hello 你好，我叫小明。…" and "Míngtiān zàijiàn!See you". The engine's `answer` column drops the question only when the answer template contains `<hr id=answer>`, and our bundled "Chinese vocab (2-way)" answer uses `<hr class="rule">` with no marker. Its divs also sit next to each other with no whitespace, so the engine's text-line rendering glues them together. Desktop Anki would show the same rows for this note type, so the fix belongs in the template, not in Browse.

## What Changes
- `ChineseNotetype` answer templates mark the split with `<hr id="answer" class="rule">`, so the question is above the rule and the answer below it:
  - Hanzi → English: the hanzi head (picture, hanzi, pinyin, audio) above the rule; English and the example below. The card looks the same as now.
  - English → Hanzi: the English line above the rule; the picture, hanzi, pinyin, audio and example below.
- Put a newline between block elements (or a `<br>`) so the engine's text line keeps separators between the example sentence, its pinyin and its English.
- Existing installs keep their note type. Only a new collection gets the new templates; no migration in this change.
- Browse keeps using the engine's `answer` column. `BrowseScreen.plain` stays as the HTML-to-text pass.

## Impact
`app/Cornhub/Backend/ChineseNotetype.swift`. Check that the review screen still matches the mockup (11-review-answer).
