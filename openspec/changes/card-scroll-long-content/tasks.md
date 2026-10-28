## 1. Fix
- [x] 1.1 Let the card web view scroll vertically: enable its scroll view for vertical pans only (indicators subtle, no bounce) while the SwiftUI card keeps taps and the horizontal grade drag; arbitrate by the first movement's axis
- [x] 1.2 Scroll to top on each new card; on reveal scroll to `#answer` when it is below the fold
- [x] 1.3 Top/bottom edge fades (Ink tokens) shown only while there is more content in that direction
- [x] 1.4 Replay button overlays the bottom-right corner on a small material circle (44 pt target); remove the reserved bottom strip; add bottom content inset so the last line clears it
- [x] 1.5 Picture tap probe (`CardImageProbe`) still finds the picture after scrolling (account for scroll offset)

## 2. Proof
- [ ] 2.1 UI test with an invented long card (several lines plus a fixture picture at the end): the picture's bottom is outside the card at first; after a vertical swipe inside the card it is inside the card; screenshots before and after
- [ ] 2.2 UI test: a mostly horizontal drag on the long card still grades Good and the next card is at its top
- [ ] 2.3 Unit test on the axis decision (vertical vs horizontal first movement) if it is a pure function
