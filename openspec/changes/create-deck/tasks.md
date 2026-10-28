## 1. Create
- [ ] 1.1 Home **+** opens a menu: Add card, New deck (VoiceOver labels)
- [ ] 1.2 New deck sheet: focused name field, `::` hint, trimmed, empty disables Create, duplicate name shows an inline error; creates through `addDeck`; tree refreshes and the new deck is scrolled to and highlighted; Undo toast
- [ ] 1.3 Deck screen ⋯ › "New subdeck…" opens the sheet prefilled with `Parent::`
- [ ] 1.4 Add card right after creating defaults to the new deck

## 2. Proof
- [ ] 2.1 Unit tests (engine): create "Testdeck", "Testdeck::Sub" makes a subdeck, a duplicate name is reported before calling the engine, undo removes the new deck
- [ ] 2.2 A UI test: + › New deck, type a name, Create, and the tile appears; + › Add card shows that deck selected; ⋯ › New subdeck on it creates a child. Review the screenshots
