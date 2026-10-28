import SwiftUI

/// "Use Cornhub layout" for a note type: confirm which field plays which role, preview a real card before and
/// after, apply through the engine, undo, restore the original layout, and the prompt to sync so desktop gets it.
struct NotetypeLayoutSheet: View {
    let backend: Backend
    let notetypeID: Int64
    var sync: SyncModel?
    var onChange: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var notetype: Anki_Notetypes_Notetype?
    @State private var mapping = NotetypeLayout.Mapping()
    @State private var note: Anki_Notes_Note?
    @State private var beforeHTML: String?
    @State private var afterHTML: String?
    @State private var errorMessage: String?
    @State private var applied = false

    private var names: [String] { notetype?.fields.map(\.name) ?? [] }
    private var restorable: Bool { notetype.map(NotetypeLayout.canRestore) ?? false }
    private var currentCSS: String { notetype?.config.css ?? "" }

    var body: some View {
        NavigationStack {
            List {
                if let notetype {
                    Section {
                        Text("This rewrites how \(notetype.name) cards are laid out on every device after you sync, including desktop Anki. No fields or notes change, and the old layout is kept so you can restore it.")
                            .foregroundStyle(Theme.text2).listRowBackground(Theme.surface)
                    }
                    Section("Fields") {
                        ForEach(NotetypeLayout.Role.allCases) { role in rolePicker(role) }
                        Toggle("Show example on the front", isOn: $mapping.showExampleOnFront)
                            .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                            .accessibilityIdentifier("layout-example-front")
                    }
                    Section("Audio") {
                        ForEach(names, id: \.self) { name in
                            Toggle(name, isOn: audioBinding(name))
                                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                        }
                    }
                    let hidden = mapping.unmapped(in: names)
                    if !hidden.isEmpty {
                        Section("Not shown on the card") {
                            ForEach(hidden, id: \.self) { Text($0).foregroundStyle(Theme.muted).listRowBackground(Theme.surface) }
                        }
                        .accessibilityIdentifier("layout-not-shown")
                    }
                    Section(restorable ? "Current (Cornhub layout)" : "Before") { preview(html: beforeHTML, css: currentCSS) }
                    if !restorable {
                        Section("After") {
                            preview(html: afterHTML, css: NotetypeLayout.css(original: currentCSS))
                        }
                    }
                    actions
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(Theme.again).listRowBackground(Theme.surface) }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Cornhub layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() }.accessibilityIdentifier("layout-done") }
            .task { await load() }
            .onChange(of: mapping) { Task { await refreshAfter() } }
        }
    }

    @ViewBuilder
    private var actions: some View {
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
                    .accessibilityIdentifier("layout-sync")
                }
                Button("Undo", systemImage: "arrow.uturn.backward") { Task { await undo() } }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("layout-undo")
            } else {
                Button("Use Cornhub layout") { Task { await apply() } }
                    .disabled(mapping[.hanzi] == nil)
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("layout-apply")
            }
            if restorable && !applied {
                Button("Restore original layout") { Task { await restore() } }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("layout-restore")
            }
        }
    }

    private func rolePicker(_ role: NotetypeLayout.Role) -> some View {
        Picker(role.title, selection: Binding(get: { mapping[role] ?? "" }, set: { mapping[role] = $0.isEmpty ? nil : $0 })) {
            Text("None").tag("")
            ForEach(names, id: \.self) { Text($0).tag($0) }
        }
        .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
        .accessibilityIdentifier("layout-role-\(role.rawValue)")
    }

    private func audioBinding(_ name: String) -> Binding<Bool> {
        Binding(
            get: { mapping.audio.contains(name) },
            set: { on in
                mapping.audio.removeAll { $0 == name }
                if on { mapping.audio.append(name) }
            })
    }

    @ViewBuilder
    private func preview(html: String?, css: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.reviewCard).fill(Theme.card)
            if let html {
                CardWebView(html: html, css: css).padding(12)
            } else {
                Text("No card of this note type yet.").foregroundStyle(Theme.muted)
            }
        }
        .frame(height: 300)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Card preview")
    }

    private func answerHTML(_ card: RenderedCard) async -> String {
        (try? await backend.extractAvTags(text: card.answer, question: false))?.0 ?? card.answer
    }

    private func load() async {
        do {
            let loaded = try await backend.getNotetype(id: notetypeID)
            notetype = loaded
            mapping = NotetypeLayout.guess(fields: loaded.fields.map(\.name), frontTemplate: NotetypeLayout.originalFront(loaded))
            let escaped = loaded.name.replacingOccurrences(of: "\"", with: "\\\"")
            if let card = try await backend.browserSearch("\"note:\(escaped)\"", notes: false).first {
                beforeHTML = await answerHTML(try await backend.renderExistingCard(id: card))
                if let noteID = try await backend.browserSearch("\"note:\(escaped)\"", notes: true).first {
                    note = try await backend.getNote(id: noteID)
                }
            }
            await refreshAfter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshAfter() async {
        guard let notetype, let note, let template = notetype.templates.first, !applied else { return }
        var edited = NotetypeLayout.applying(mapping, to: notetype)
        edited.id = notetype.id
        do {
            afterHTML = await answerHTML(try await backend.renderUncommittedCard(
                note: note, ordinal: 0, template: edited.templates.first ?? template))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save(_ edited: Anki_Notetypes_Notetype) async -> Bool {
        do {
            try await backend.updateNotetype(edited)
            notetype = try await backend.getNotetype(id: notetypeID)
            errorMessage = nil
            onChange()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func apply() async {
        guard let notetype else { return }
        if await save(NotetypeLayout.applying(mapping, to: notetype)) { applied = true }
    }

    private func restore() async {
        guard let notetype, let restored = NotetypeLayout.restoring(notetype) else { return }
        if await save(restored) { applied = true }
    }

    private func undo() async {
        do {
            try await backend.undo()
            notetype = try await backend.getNotetype(id: notetypeID)
            applied = false
            onChange()
            await refreshAfter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
