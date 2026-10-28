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

### Requirement: Card audio
The review screen SHALL extract `[sound:]` tags with `extract_av_tags`, play files from collection.media with AVAudioPlayer, auto-play the side shown, and offer a speaker button to replay.

#### Scenario: Replay
- **WHEN** the user taps the speaker button
- **THEN** the side's audio plays again

### Requirement: TTS tags
`{{tts}}` tags SHALL be spoken with AVSpeechSynthesizer, choosing a voice matching the tag's language and the engine's `all_tts_voices` list.

#### Scenario: Speak
- **WHEN** a side contains a TTS tag
- **THEN** its text is spoken

### Requirement: Type-in answer
Cards with a type-answer field SHALL show a native text field on the question side, and the answer side SHALL show the engine's `compare_answer` diff, using `extract_cloze_for_typing` for cloze cards.

#### Scenario: Typed answer
- **WHEN** the user types an answer and reveals
- **THEN** the diff from `compare_answer` is shown

### Requirement: Media and math in cards
Images and other media SHALL load in the card web view from collection.media through a custom URL scheme, and MathJax 3 bundled in the app SHALL typeset math. LaTeX image generation is out of scope.

#### Scenario: Image
- **WHEN** a card references `<img src="a.png">`
- **THEN** the image loads from collection.media

### Requirement: Start review studies all due decks
Start review (opened with no deck) SHALL study cards from every deck that has due cards, using due counts from `deck_tree`. It SHALL set each such deck current in turn and show the congrats screen only when no deck has due cards left.

#### Scenario: Cards due in a non-current deck
- **WHEN** HSK 1 has 45 new cards, the engine's current deck is the empty Default deck, and the user taps Start review
- **THEN** the review screen shows an HSK 1 question, not the congrats screen

### Requirement: Review at accessibility text sizes
The review screen SHALL stay usable at the largest accessibility text size: grade labels never break mid-word, header buttons don't overlap, and the card content shows.

#### Scenario: Largest text size
- **WHEN** the user opens review with Dynamic Type set to the largest accessibility size
- **THEN** the card question is visible, the Again, Hard, Good and Easy labels are whole words, and the close, undo and ⋯ buttons don't overlap

### Requirement: Speak pronounces the word only
The Speak action SHALL play the note's own audio when it has any, and otherwise speak only the card's headword. It SHALL NOT read pinyin, translations or example sentences.

#### Scenario: Chinese vocab card without audio
- **WHEN** the user taps Speak on a 你好 card whose Audio field is empty
- **THEN** the device speaks "你好" only

#### Scenario: Card with audio
- **WHEN** the note's Audio field holds `[sound:nihao.mp3]`
- **THEN** Speak plays that file instead of TTS

### Requirement: Show answer capsule
On the question side, the review screen SHALL show a single "Show answer" capsule where the grade bar goes, and SHALL NOT show disabled grade buttons.

#### Scenario: Before reveal
- **WHEN** a card's question is showing
- **THEN** a "Show answer" capsule sits at the bottom and no Again, Hard, Good or Easy buttons are visible

#### Scenario: Reveal
- **WHEN** the user taps the capsule or the card
- **THEN** the answer shows and the capsule turns into the four grade buttons with their intervals

### Requirement: No dead controls on the congrats screen
The "All done for now" screen SHALL show only header controls that do something: close always, Undo only when an answer can be undone, and ⋯ only when it has an enabled action.

#### Scenario: Nothing to undo
- **WHEN** the review opens straight to "All done for now" with nothing graded
- **THEN** the header shows only the close button

#### Scenario: Undo the last answer
- **WHEN** the user grades the last due card, sees "All done for now" and taps Undo
- **THEN** that card shows again on its question side, and the counts include it

### Requirement: Imported note types render readably
Cards from imported note types SHALL keep their own CSS. When a note type sets a light card background without a text colour, the default text SHALL be dark, as on desktop. Default text SHALL never be unreadable against the card's own background.

#### Scenario: Light background, no text colour
- **WHEN** the user reviews a card whose note type sets `.card { background-color: #fdf6e3 }` and no colour
- **THEN** the headword, meaning and sentence show as dark text on the cream card

#### Scenario: No styling
- **WHEN** a note type sets no background
- **THEN** the card uses the Ink look

### Requirement: Imported media plays and shows
Images and sounds referenced by imported notes SHALL load from the collection's media folder. A missing image SHALL show an Ink placeholder instead of a broken-image icon.

#### Scenario: Sentence image
- **WHEN** a card's field has `<img src="x.jpg">` and `x.jpg` was imported with the deck
- **THEN** the image shows on the card

#### Scenario: Missing image
- **WHEN** the referenced image file isn't in the media folder
- **THEN** a small "Image missing" placeholder shows

### Requirement: Extras work on any note type
Speak, Explain, Translate and stroke order SHALL work on cards of any note type, using the note's audio when present and otherwise the card's own text.

#### Scenario: Speak on an imported card
- **WHEN** the user taps Speak on an imported card whose `Audio` field has `[sound:word.mp3]`
- **THEN** the sound plays, or if the file is missing, the headword is spoken with text-to-speech

#### Scenario: Speak on a note type without audio
- **WHEN** the note type has no sound fields
- **THEN** Speak says only the headword, derived from the first mostly-hanzi field
