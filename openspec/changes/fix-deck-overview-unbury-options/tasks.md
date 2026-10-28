## 1. Unbury
- [x] 1.1 Confirm whether `unburyDeck` unburies (a test with a buried card) and fix it if not
- [x] 1.2 Unbury shows only when the deck has buried cards; afterwards the counts refresh, "Unburied N cards" shows, and errors show. With no buried cards the button is gone and Custom study takes the full row width (no empty half)

## 2. Deck options page
- [x] 2.1 Phone layout for the header via injected CSS: margins, equal 44 pt heights, accent Save split button, no overflow, truncating preset name
- [x] 2.2 Native Done doesn't lose edits: it saves first or asks Save / Discard / Cancel

## 3. Proof
- [ ] 3.1 A unit test: bury a card in a seeded deck, then `unburyDeck`, and the card is no longer buried and counts include it
- [ ] 3.2 A UI test: with a buried card seeded through a launch argument, the overview shows Unbury; tapping it shows the confirmation and the button disappears. With nothing buried, there's no Unbury button
- [ ] 3.3 `testHomeAndDeckOverview` passes. Review 04-deck-options-web (header margins, equal heights, nothing cut off) and 03-deck-overview. A UI test changes "New cards/day" and taps Done, then reopening the page shows the saved value (or the prompt appears, per 2.2)
