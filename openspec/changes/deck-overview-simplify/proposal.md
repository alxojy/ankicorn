## Why
User feedback on the deck screen (Mandarin (HSK) screenshot): "this UI too much, you need to simplify." From top to bottom it stacks:
- a giant glyph and the card count;
- three large stat tiles (New, Learning, Review);
- a full-width Study button;
- three more full-width grey buttons (Custom study, Browse cards, Deck options), each as tall as Study;
- a "SUBDECKS" header with a collapse chevron;
- big subdeck tiles.

The ⋯ menu at the top right already has Rename, Options and Delete. On a phone the subdecks, which are often the point of a parent deck, start below the fold.

## What Changes
- **One compact header:** the deck name is the title. Below it, one line: total cards and the due counts as coloured numbers in the home screen's style (`0 new · 75 learning · 500 review`, using the new/learn/review tokens). The giant glyph and the three stat tiles go.
- **One primary action:** the Study button stays, full width, the only large button. When nothing is due it reads "Nothing due" and is disabled, with "Custom study" as a text link under it.
- **Secondary actions in the ⋯ menu:**
  - Custom study, Browse cards, Deck options and Unbury (when buried cards exist) join Rename and Delete in the top-right ⋯ menu, grouped: study actions, then manage actions, then Delete (destructive).
  - No full-width grey buttons remain.
  - Browse cards also stays reachable as a small icon button next to ⋯ if that reads better; pick one and keep it consistent.
- **Subdecks as a list:** compact rows: the name, then the due counts in the same coloured style, a chevron, and the existing tile glyph small at the leading edge. No section collapse chevron. Tapping a row opens that subdeck. The rows have the same long-press menu as the home tiles (Rename, Options, Delete).
- The screen fits on one phone screen for a deck with up to about 6 subdecks, with the tab bar showing.

## Impact
`Screens/DeckHome/DeckOverviewScreen.swift` (and the action items view it shares with the home tiles), and tests that tap the removed buttons (`ScreenTourUITests`: custom study, unbury, deck options, browse from overview) must now go through the ⋯ menu.
