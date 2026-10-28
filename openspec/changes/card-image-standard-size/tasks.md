## 1. Standard size
- [ ] 1.1 Card images fit the card width and a max height of about a third of the visible card height (cap 220 pt), aspect ratio kept, centred, not upscaled
- [ ] 1.2 The rule wins over note-type CSS for image size; other deck styling still applies; app assets (stroke order) are unaffected

## 2. Full size on tap
- [ ] 2.1 Tapping a card picture opens it full screen (zoom, swipe down or ✕ to close); taps elsewhere still show the answer and swipes still grade

## 3. Proof
- [ ] 3.1 A UI test on the imported-deck fixture's answer side (sentence plus picture): the picture's bottom edge is inside the card and its height is at most the cap; a note type whose CSS sets `img { width: 100%; height: 600px }` is still capped
- [ ] 3.2 A UI test: tap the picture and the full-screen viewer shows, then close it and the card is unchanged
- [ ] 3.3 Review the answer screenshots for the light and dark fixtures
