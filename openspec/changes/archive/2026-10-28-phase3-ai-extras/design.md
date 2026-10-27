## Decisions
- Explanations: `FoundationModels` when `SystemLanguageModel.default.availability == .available`, else the Claude Messages API with the Keychain key, else an "unavailable" message. Cache is a JSON file keyed by note ID and a hash of the card text.
- Stroke order: hanzi-writer (MIT) and hanzi-writer-data (Make Me a Hanzi, Arphic Public License) load from jsDelivr inside a WKWebView on demand; nothing is bundled. Attribution is shown in the panel; offline shows a message.
- Translation uses `TranslationSession` through a `.translationTask` modifier; unavailable languages show a message.
- Deck speech language is stored in UserDefaults keyed by deck ID.
