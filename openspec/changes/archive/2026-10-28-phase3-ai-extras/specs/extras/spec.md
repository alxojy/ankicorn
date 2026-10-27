## ADDED Requirements

### Requirement: Speech for any card
The answer side SHALL offer a Speak action that reads the card text with AVSpeechSynthesizer in the deck's configured voice language.

#### Scenario: Speak
- **WHEN** the user taps Speak
- **THEN** the card text is spoken using a voice matching the deck language

### Requirement: Translation
The answer side SHALL offer a Translate action using Apple's Translation framework and show a message when translation is unavailable.

#### Scenario: Unavailable
- **WHEN** the language pair cannot be translated
- **THEN** a message is shown instead of a translation

### Requirement: Explanation
The Explain chip SHALL generate an explanation with Apple Foundation Models, falling back to the Claude API with a Keychain-stored key, and cache the result per note.

#### Scenario: Cached
- **WHEN** the user taps Explain on a note explained before
- **THEN** the cached explanation is shown without generating again

#### Scenario: No model
- **WHEN** neither Foundation Models nor an API key is available
- **THEN** the panel says so and points to Settings

### Requirement: Stroke order
The answer side SHALL offer a Stroke order action for notes containing hanzi, animating strokes from open hanzi-writer data.

#### Scenario: Offline
- **WHEN** stroke data cannot be loaded
- **THEN** a message is shown

### Requirement: Auto-fill
The Add card screen SHALL offer an "Auto-fill example, audio and picture" action that fills empty fields it can from the headword, and does nothing destructive when generation is unavailable.

#### Scenario: Unavailable
- **WHEN** no model is available
- **THEN** the screen shows a message and fields are unchanged
