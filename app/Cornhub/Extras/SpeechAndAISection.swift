import SwiftUI

/// Settings: per-deck speech language and the optional Claude API key for explanations.
struct SpeechAndAISection: View {
    let backend: Backend?
    @State private var key = ClaudeKeychain.load() ?? ""
    @State private var decks: [Anki_Decks_DeckNameId] = []
    @State private var revision = 0

    var body: some View {
        Section {
            SecureField("Claude API key (optional)", text: $key)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .frame(minHeight: Theme.minTarget)
                .onSubmit { ClaudeKeychain.save(key) }
                .onChange(of: key) { _, value in ClaudeKeychain.save(value) }
                .accessibilityIdentifier("settings-claude-key")
                .listRowBackground(Theme.surface)
            ForEach(decks, id: \.id) { deck in
                Picker(deck.name, selection: Binding(
                    get: { SpeechSettings.language(deckID: deck.id) },
                    set: { SpeechSettings.setLanguage($0, deckID: deck.id); revision += 1 })
                ) {
                    ForEach(SpeechSettings.languages, id: \.code) { Text($0.name).tag($0.code) }
                }
                .frame(minHeight: Theme.minTarget)
                .listRowBackground(Theme.surface)
            }
        } header: {
            Text("Speech and explanations")
        } footer: {
            Text("Explanations use Apple Intelligence when available; otherwise the Claude API (\(TextGenerator.claudeModel)) with this key, stored in the Keychain.")
        }
        .task(id: backend == nil) { if let backend { decks = (try? await backend.deckNames()) ?? [] } }
    }
}
