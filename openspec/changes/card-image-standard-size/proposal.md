## Why
On tall answer cards (a headword, sentence, translation and a picture, as in the user's imported HSK+ deck), the picture runs off the bottom of the card and is cut off. The card view doesn't scroll. The user asked for pictures at a standard size instead.

What the code does now: `CardWebView.baseCSS` sets only `img { max-width: 100%; border-radius: 20px; }`. Height is unlimited, so a landscape photo at full card width can take up half the screen or more. The note's own CSS comes after the base CSS and can make images bigger.

## What Changes
- **One standard picture size on cards:** every `<img>` in a card's question or answer fits within the card's width and a fixed maximum height. That height is about a third of the card's visible height, capped at 220 pt, with the aspect ratio kept (`object-fit: contain`, `width: auto; height: auto`). Pictures are centred, keep the existing rounded corners, and small pictures aren't scaled up.
- **It applies to every note type.** The rule is injected after the note's CSS (or with enough specificity), so a deck's own image styling can't make pictures bigger than the standard size. Deck styling for other things (borders, alignment) still applies.
- **Tap to view full size:** tapping a picture opens it full screen (zoomable, dismiss with a swipe down or ✕), so detail isn't lost. This needs a message from the web view to Swift; images stay non-interactive otherwise, and taps elsewhere on the card keep working as now (show answer and swipe).
- Image occlusion is out of scope (not built yet); the rule must not affect `cornhub://app/` assets such as the stroke-order view.

## Impact
`Screens/Review/CardWebView.swift` (CSS and the tap handler), a small full-screen image viewer view, and tests. The editor preview and card info aren't changed.
