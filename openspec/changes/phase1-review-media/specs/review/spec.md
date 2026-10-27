## ADDED Requirements

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
