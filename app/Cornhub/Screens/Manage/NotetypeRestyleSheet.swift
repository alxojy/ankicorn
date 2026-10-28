import SwiftUI

/// "Use Cornhub style" for a note type: before/after preview of a real card, apply through the engine, undo,
/// restore the original, and the prompt to sync so desktop gets the new CSS too.
struct NotetypeRestyleSheet: View {
    let backend: Backend
    let notetypeID: Int64
    var sync: SyncModel?
    var onChange: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var notetype: Anki_Notetypes_Notetype?
    @State private var cardHTML: String?
    @State private var errorMessage: String?
    @State private var applied = false

    private var currentCSS: String { notetype?.config.css ?? "" }
    private var restorable: Bool { NotetypeStyle.canRestore(css: currentCSS) }
    private var originalCSS: String { NotetypeStyle.previous(in: currentCSS) ?? currentCSS }
    private var newCSS: String { NotetypeStyle.generate(from: currentCSS) }

    var body: some View {
        NavigationStack {
            List {
                if let notetype {
                    Section {
                        Text("This changes how \(notetype.name) cards look on every device after you sync, including desktop Anki. The old style is kept so you can restore it.")
                            .foregroundStyle(Theme.text2)
                            .listRowBackground(Theme.surface)
                    }
                    Section(restorable ? "Current (Cornhub style)" : "Before") { preview(css: currentCSS) }
                    Section(restorable ? "Original style" : "After") {
                        preview(css: restorable ? originalCSS : newCSS)
                    }
                    Section {
                        if applied {
                            Label("Saved. Sync to update desktop.", systemImage: "checkmark.circle")
                                .foregroundStyle(Theme.text).listRowBackground(Theme.surface)
                            if let sync, sync.isSignedIn {
                                Button(sync.isSyncing ? "Syncing…" : "Sync now", systemImage: "arrow.triangle.2.circlepath") {
                                    Task { await sync.sync(backend: backend) }
                                }
                                .disabled(sync.isSyncing)
                                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                                .accessibilityIdentifier("restyle-sync")
                            }
                            Button("Undo", systemImage: "arrow.uturn.backward") { Task { await undo() } }
                                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                                .accessibilityIdentifier("restyle-undo")
                        } else {
                            Button("Use Cornhub style") { Task { await apply(newCSS) } }
                                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                                .accessibilityIdentifier("restyle-apply")
                        }
                        if restorable && !applied {
                            Button("Restore original style") { Task { await apply(originalCSS) } }
                                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                                .accessibilityIdentifier("restyle-restore")
                        }
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(Theme.again).listRowBackground(Theme.surface) }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Cornhub style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() }.accessibilityIdentifier("restyle-done") }
            .task { await load() }
        }
    }

    @ViewBuilder
    private func preview(css: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.reviewCard).fill(Theme.card)
            if let cardHTML {
                CardWebView(html: cardHTML, css: css).padding(12)
            } else {
                Text("No card of this note type yet.").foregroundStyle(Theme.muted)
            }
        }
        .frame(height: 260)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Card preview")
    }

    private func load() async {
        do {
            let loaded = try await backend.getNotetype(id: notetypeID)
            notetype = loaded
            let escaped = loaded.name.replacingOccurrences(of: "\"", with: "\\\"")
            if let card = try await backend.browserSearch("\"note:\(escaped)\"", notes: false).first {
                let rendered = try await backend.renderExistingCard(id: card)
                cardHTML = (try? await backend.extractAvTags(text: rendered.answer, question: false))?.0 ?? rendered.answer
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ css: String) async {
        guard var edited = notetype else { return }
        edited.config.css = css
        do {
            try await backend.updateNotetype(edited)
            notetype = try await backend.getNotetype(id: notetypeID)
            applied = true
            errorMessage = nil
            onChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func undo() async {
        do {
            try await backend.undo()
            notetype = try await backend.getNotetype(id: notetypeID)
            applied = false
            onChange()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
