## Why
User screenshot of an imported HSK card (行, answer side) on iPhone: the picture at the bottom is cut off mid-way at the card's edge, and nothing on the card can be scrolled. Anything below the fold (pictures, a second example, notes) is unreachable.

Cause, observed in code:
- **No scrolling:** `CardWebView` sets `isUserInteractionEnabled = false`, so the SwiftUI card owns taps and swipes. The web view's own scroll view never gets a touch.
- **Fixed height:** the card panel takes the space left between the counts and the extras row (`.frame(minHeight: 160, maxHeight: .infinity)`), so a card taller than that space is clipped by the frame.
- **Less room:** `review-card-polish` added a 44 pt replay strip below the card HTML, which costs height on every card with audio.
- Pictures are already capped at `min(imageMaxHeight, 33vh)` by `card-image-standard-size`, so the picture is the right size. It's the card that has no room for it.

## What Changes
- **Vertical scrolling inside the card:** when the rendered card is taller than its frame, the user can scroll it up and down with one finger. Horizontal swipes still grade (Good/Again), taps still reveal the answer and open a picture. The gesture locks to an axis on the first movement: mostly vertical means scroll, mostly horizontal means the grade swipe.
- **More-content hint:** while there's more content below (or above), a short fade at that edge of the card shows that it scrolls. It goes away at the end.
- **Start at the top:** each new card and each reveal starts scrolled to the top. Revealing the answer scrolls to the answer divider (`#answer`, as Anki does) when it's below the fold.
- **Replay doesn't take a strip:** the replay button floats over the card's bottom-right corner on a small Ink material circle, instead of reserving 44 pt under the card. Card content gets bottom padding so the last line can scroll clear of the button.
- **Scrolling is on the engine's HTML:** no content is reflowed or removed in Swift; the web view's own scroll view does the scrolling (keep it non-bouncing, indicators hidden or subtle).

## Impact
`Screens/Review/CardWebView.swift` (scroll enabling, scroll-to-top / scroll-to-answer, content insets, fade), `Screens/Review/ReviewScreen.swift` (gesture arbitration with the swipe-to-grade drag, replay button overlay), tests. Interacts with `review-card-polish` (replay placement) and `card-image-standard-size` (picture tap probe).
