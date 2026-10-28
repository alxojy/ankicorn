## 1. Fix
- [x] 1.1 Stats header: leaf name in a screen-title display size, one line, tail truncation, chevron visible, parent path as a muted caption for subdecks; constrained to the screen width
- [x] 1.2 Stats deck picker lists decks as a tree by leaf name (indented or nested), ✓ on the current one; no `::` in the UI
- [x] 1.3 Audit the review header, deck overview title and Browse deck chip for the same clipping; fix any that clip

## 2. Proof
- [ ] 2.1 A unit test: leaf name and parent path from `A::B::C`
- [ ] 2.2 A UI test: in Stats pick a subdeck with a long parent name; the header label's frame lies within the screen's width and the chevron is visible; the caption shows the parent. Screenshot reviewed
