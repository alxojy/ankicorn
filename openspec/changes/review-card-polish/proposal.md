## Why
User feedback on the imported 也许 card (answer side screenshot): "if image missing no need to show it", and the card doesn't look like the app. On that screenshot:
1. **"Image missing" pill.** `imported-deck-compat` replaced WebKit's broken "?" with an "Image missing" placeholder. The user doesn't want anything shown.
2. **The ▶︎ replay icon overlaps the card's top-right corner.** It sits half over the deck's own card box and half over the Ink frame.
3. **Translate fails** with "An unsupported language or locale was used". `ExtrasModel.translate` builds the source language from the deck's speech setting (`SpeechSettings.language(deckID:)`). For an imported deck that was never set, it defaults to a non-Chinese language, so the request becomes en → en, or another unsupported pair.
4. The raw error string also shows in a plain panel, not in the app's style.
5. **Explain fails with the same message on imported cards** (怎么样 screenshot; the user tested Explain on our own cards before and it worked there). The message is Foundation Models' `unsupportedLanguageOrLocale` error, passed through by `TextGenerator.generate` as `error.localizedDescription`. `ExtrasModel.explain` sends `allText`, the whole rendered question plus answer. On these cards that is mostly hanzi (the question again, the sentence, pinyin, tone-marked text), and the model rejects it as an unsupported prompt language for the device's Apple Intelligence language.

## What Changes
- **Missing images disappear:** a missing `<img>` is removed from the layout (no placeholder, no gap, no broken icon). Remove the "Image missing" placeholder. If a missing image leaves an empty wrapper or `<br>` run at the end of the card, trim that trailing blank space.
- **Replay button placement:** the ▶︎ (note audio) button sits in the app's own chrome, not on top of the card content. Put it in the bottom-right of the Ink frame, or in the extras row next to Speak; pick one and keep it consistent. It must not overlap the card's HTML.
- **Translate picks the right languages:**
  - **Source language:** detected from the card text (`NLLanguageRecognizer`, with hanzi giving `zh-Hans`). The deck's speech language is only a fallback.
  - **Target language:** the device language.
  - **Same language:** if source and target are the same, say "Already in English" (or the target's name) instead of calling the API.
  - **Unavailable:** if the pair isn't available on the device, show one friendly line: "Translation for Chinese isn't available on this device. Download it in Settings › Apps › Translate." Never show the raw system error.
- **Explain works on Chinese cards:**
  - **Smaller prompt:** build it from the derived headword, its pinyin, the meaning and one example sentence (from `imported-deck-compat`'s headword logic), not the whole rendered card. Duplicates go, and so do sound or play markers.
  - **Instructions:** written in the device language, naming the locale, as Apple recommends (for example "The person's locale is en_US. Respond in English."). The Chinese is quoted as the material being explained.
  - **Language check:** check `SystemLanguageModel.default.supportsLocale(_:)` for the device locale first.
  - **Retry:** on `unsupportedLanguageOrLocale`, retry once with a romanised prompt (pinyin plus English only, and the hanzi count stated).
  - **If it still fails:** show "Explain isn't available in this language on this device" in the app style, never the raw error.
- **Extras messages in the app style:** the extras result panel (explain, translate, errors) uses the Ink surface, radius and type tokens. Error lines are in muted text with an SF Symbol, not plain system text.

## Impact
`Screens/Review/CardWebView.swift` (missing image handling), `ReviewScreen.swift` (replay button), `Extras/ExtrasModel.swift` and the extras panel view, and tests.
