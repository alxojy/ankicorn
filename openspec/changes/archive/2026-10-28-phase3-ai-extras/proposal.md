## Why
PLAN.md "Extras" and the Review answer-side chips: speech, translation, AI explanations, stroke order and Add-card auto-fill.

## What Changes
- Speech chip: AVSpeechSynthesizer for any card, voice language per deck.
- Translate chip: Apple Translation framework.
- Explain chip: Apple Foundation Models, optional Claude API key (Keychain, model claude-sonnet-5-5) as fallback; explanation panel cached per note.
- Stroke order chip for hanzi (hanzi-writer-data, bundled for needed characters or fetched on demand).
- Add card "Auto-fill example, audio and picture" button.
- Everything degrades gracefully when a framework or key is unavailable.
