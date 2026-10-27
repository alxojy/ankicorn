## ADDED Requirements

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
