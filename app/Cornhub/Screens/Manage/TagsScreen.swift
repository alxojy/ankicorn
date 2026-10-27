import SwiftUI

/// All tags with rename, move under another tag, delete, and clear unused.
struct TagsScreen: View {
    let backend: Backend
    @State private var tags: [String] = []
    @State private var loaded = false
    @State private var renaming: String?
    @State private var reparenting: String?
    @State private var text = ""
    @State private var message: String?

    var body: some View {
        List {
            if loaded && tags.isEmpty {
                Text("No tags yet.").foregroundStyle(Theme.muted).listRowBackground(Theme.surface)
            }
            ForEach(tags, id: \.self) { tag in
                Text(tag).foregroundStyle(Theme.text)
                    .frame(minHeight: Theme.minTarget, alignment: .leading).listRowBackground(Theme.surface)
                    .swipeActions {
                        Button("Delete", role: .destructive) { Task { await remove(tag) } }
                    }
                    .contextMenu {
                        Button("Rename", systemImage: "pencil") { text = tag; renaming = tag }
                        Button("Move under…", systemImage: "arrow.turn.down.right") { text = ""; reparenting = tag }
                        Button("Delete", systemImage: "trash", role: .destructive) { Task { await remove(tag) } }
                    }
            }
            if let message { Text(message).foregroundStyle(Theme.muted).listRowBackground(Theme.surface) }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Clear unused") { Task { await clearUnused() } }.accessibilityIdentifier("tags-clear-unused")
        }
        .task { await reload() }
        .alert("Rename tag", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("New name", text: $text)
            Button("Rename") { if let old = renaming { Task { await rename(old) } } }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Move under tag", isPresented: Binding(get: { reparenting != nil }, set: { if !$0 { reparenting = nil } })) {
            TextField("Parent tag (empty for top level)", text: $text)
            Button("Move") { if let tag = reparenting { Task { await reparent(tag) } } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func reload() async {
        tags = (try? await backend.allTags()) ?? []
        loaded = true
    }

    private func run(_ work: () async throws -> Void) async {
        do { try await work(); message = nil } catch { message = error.localizedDescription }
        await reload()
    }

    private func rename(_ old: String) async {
        let new = text.trimmingCharacters(in: .whitespaces)
        guard !new.isEmpty else { return }
        await run { try await backend.renameTag(from: old, to: new) }
    }

    private func reparent(_ tag: String) async {
        await run { try await backend.reparentTags([tag], under: text.trimmingCharacters(in: .whitespaces)) }
    }

    private func remove(_ tag: String) async {
        await run { try await backend.removeTags(tag) }
    }

    private func clearUnused() async {
        await run {
            let count = try await backend.clearUnusedTags()
            message = count == 0 ? "No unused tags." : "Removed \(count) unused tags."
        }
    }
}
