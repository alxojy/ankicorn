## Why
In the sweep, Card info failed with "Your database appears to be in an inconsistent state… No such deck config: '0'". `Backend.addDeck` builds `Anki_Decks_Deck` by hand with `deck.normal = Normal()`, so `config_id` is 0, and every deck the app creates (sample decks, "Parent::Child" parents, imported deck names typed by the user) points at a preset that does not exist. Desktop Anki would see the same broken decks after a sync, and deck options and scheduling may fall back unpredictably.

## What Changes
- `addDeck` starts from the engine's template, the `new_deck` backend method (Decks service), sets only the name, then calls `add_deck`. The template carries `config_id` 1 and the engine's other defaults.
- Collections that already contain such decks are repaired by calling `check_database` once at open when a deck with a missing config is detected, or simply once after open on first launch of this version. Prefer the engine's repair over Swift fixes.
- Review the other hand-built protobuf "new object" paths (filtered decks, note types, notes) for the same mistake. Use the engine's `new_*`/`defaults_*` methods wherever they exist.

## Impact
`app/Cornhub/Backend/Backend+Decks.swift`, collection open path (`DeckHomeModel`), possibly `Backend+Manage.swift` and `Backend+NoteEditing.swift`.
