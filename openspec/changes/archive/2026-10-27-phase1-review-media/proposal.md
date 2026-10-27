## Why
Cards with audio, TTS, type-in answers, cloze and math render incompletely. Review needs media parity.

## What Changes
- Card audio via `extract_av_tags`, played with AVAudioPlayer from collection.media, auto-play and replay button.
- `{{tts}}` tags spoken with AVSpeechSynthesizer.
- Type-in answer field with `compare_answer` and `extract_cloze_for_typing`.
- Media served to the card web view through a custom scheme; MathJax 3 bundled for `\(..\)` and `\[..\]`.
