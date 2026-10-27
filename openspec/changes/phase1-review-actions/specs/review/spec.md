## ADDED Requirements

### Requirement: Card actions while reviewing
The Review header menu SHALL let the user flag the current card with one of seven flags (`set_flag`), mark or unmark its note (the `marked` tag via `add_note_tags` and `remove_note_tags`), bury or suspend the card (`bury_or_suspend_cards`), and open card info, which MAY be a placeholder until the web bridge exists. After an action that removes the card from the queue the next card SHALL appear.

#### Scenario: Suspend
- **WHEN** the user chooses Suspend in the menu
- **THEN** the card is suspended and the next card is shown

### Requirement: Edit note while reviewing
The menu SHALL offer Edit, opening a sheet with one text field per note field loaded with `get_note`, and saving SHALL call `update_notes` and re-render the card.

#### Scenario: Save an edit
- **WHEN** the user changes a field and taps Save
- **THEN** the note is updated and the card shows the new text

### Requirement: Custom study and unbury
The deck overview SHALL offer Custom study with the common options (extend new limit, extend review limit, review forgotten cards, review ahead, preview new cards, study by card state or tag) using `custom_study_defaults` and `custom_study`, and Unbury using `unbury_deck`.

#### Scenario: Extend today's new cards
- **WHEN** the user picks Increase today's new card limit and confirms
- **THEN** `custom_study` is called with that delta for the deck
