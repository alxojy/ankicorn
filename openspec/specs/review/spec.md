# review Specification

## Purpose
The full-screen review session: cards from the engine, reveal, four grades with intervals, undo, swipe to grade and the congrats screen.

## Requirements

### Requirement: Review session
The review screen SHALL open full screen from Start review and deck Study, fetch cards with `get_queued_cards`, render each card's question and answer with `render_existing_card` in a WKWebView over a base Ink stylesheet, and show remaining new, learning and review counts from the engine.

#### Scenario: Reveal
- **WHEN** the user taps the card showing a question
- **THEN** the answer is shown with the grade bar

### Requirement: Grading
The grade bar SHALL offer Again, Hard, Good and Easy, each showing the interval from `describe_next_states`, and answering SHALL call `answer_card` with the queued card's scheduling states. Undo SHALL call the engine's `undo` and show the restored card.

#### Scenario: Answer a card
- **WHEN** the user taps Good
- **THEN** `answer_card` is called with the Good state and the next card appears

### Requirement: Swipe to grade
Swiping the card right SHALL answer Good and left Again once past a threshold, while tilting the card, glowing its edge, stamping the grade and interval and giving a haptic at the threshold. A hint line SHALL explain the gesture until the user has swiped a few times.

#### Scenario: Swipe right
- **WHEN** the user drags the revealed card right past the threshold and lets go
- **THEN** the card is answered Good

### Requirement: Congrats screen
When the queue is empty the review screen SHALL show a congrats screen built from `congrats_info`.

#### Scenario: Nothing due
- **WHEN** a session starts or ends with no cards due
- **THEN** the congrats screen shows with a way back to the decks

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
