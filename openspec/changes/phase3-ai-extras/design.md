## Decisions
- Explanations: `FoundationModels` when `SystemLanguageModel.default.availability == .available`, else the Claude Messages API with the Keychain key, else an "unavailable" message. Cache is a JSON file keyed by note ID and a hash of the card text.
- Stroke order: fetched on demand from the hanzi-writer-data CDN (MIT/Arphic license, attribution in the panel) and cached on disk; drawn as SVG paths in a WKWebView animation. No bundled data.
- Translation uses `TranslationSession` through a `.translationTask` modifier; unavailable languages show a message.
- Deck speech language is stored in UserDefaults keyed by deck ID.
