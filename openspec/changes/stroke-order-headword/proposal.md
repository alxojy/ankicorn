## Why
User screenshot (怎么样 card): Stroke order shows every hanzi on the card, including 这件衣… from the example sentence, in a two-row grid. The grid is clipped at the top and bottom and squeezes the card above it. "Stroke order should only show for the word of the card."

Cause: `ExtrasModel.showStrokes()` uses `hanzi`, which is `CardText.hanzi(allText)`: every hanzi in the rendered question plus answer. `CardText.headword(names:fields:question:language:)` (added in `imported-deck-compat`) already finds the card's main word for Speak, but strokes don't use it.

## What Changes
- **Headword only:** Stroke order shows the hanzi of the card's headword (the same `CardText.headword` Speak uses), in order, with duplicates kept only once (怎么样 → 怎, 么, 样). If the headword has no hanzi, the button is hidden for that card instead of showing "No hanzi on this card".
- **One row that fits:** the panel shows the characters in a single row sized to fit the width, up to 4 per row at a comfortable size. Longer headwords (idioms) scroll horizontally. Nothing is clipped at the top or bottom. The panel's height comes from its content, and the card above isn't squeezed to an unreadable height (it may scroll if needed).
- **Animation:** each character animates its strokes in turn. Tapping a character replays it. The attribution line stays (MIT and Arphic licence notices must remain).

## Impact
`Extras/ExtrasModel.swift` (`showStrokes`, button visibility), `Extras/ExtrasPanel.swift` (strokes layout), and tests.
