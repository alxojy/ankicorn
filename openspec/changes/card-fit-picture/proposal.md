## Why
User screenshot (HSK card 感觉, answer side, after `card-scroll-long-content` merged): the card scrolls now, but at rest the picture is sliced by the card's bottom edge under a fade, with the replay button over it. It reads as "picture cut off", not "there's more below". The text above it fits; only the picture doesn't.

## What Changes
- **Fit the picture into the space left:** after the card lays out, if the content is taller than the card frame and the overflow is no more than what the pictures can give up, shrink the pictures (keeping aspect ratio, centred) so the whole card fits without scrolling. A picture never goes below a floor of 96 pt high; if it would, keep it at the standard size and let the card scroll as now.
- **Only text that doesn't fit scrolls:** scrolling stays for cards whose text alone is taller than the frame.
- **Re-fit on change:** re-run the fit on reveal, on Dynamic Type changes, on rotation and when an image finishes loading.
- **Replay button inside the card:** the floating replay circle sits fully inside the card's bottom-right corner (it now overhangs the card edge), and content keeps the bottom inset so the button never covers the picture once it fits.
- **No fade when it fits:** the bottom fade appears only when the card really scrolls.

## Impact
`Screens/Review/CardWebView.swift` (a fit script run in the page: measure content vs viewport, set `img` max-height; message back whether it still overflows), `Screens/Review/ReviewScreen.swift` (replay placement), tests. Builds on `card-image-standard-size` and `card-scroll-long-content`.
