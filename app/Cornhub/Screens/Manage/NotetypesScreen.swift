import SwiftUI

/// Note types with use counts; opens the field and template editor, find duplicates, and delete.
struct NotetypesScreen: View {
    let backend: Backend
    var sync: SyncModel?
    @State private var types: [Anki_Notetypes_NotetypeNameIdUseCount] = []
    @State private var loaded = false
    @State private var message: String?

    var body: some View {
        List {
            if loaded && types.isEmpty {
                Text("No note types.").foregroundStyle(Theme.muted).listRowBackground(Theme.surface)
            }
            ForEach(types, id: \.id) { type in
                NavigationLink {
                    NotetypeEditorScreen(backend: backend, notetypeID: type.id, sync: sync)
                } label: {
                    VStack(alignment: .leading) {
                        Text(type.name).foregroundStyle(Theme.text)
                        Text("\(type.useCount) notes").font(.inkLabel).foregroundStyle(Theme.muted)
                    }
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityLabel("\(type.name), \(type.useCount) notes")
                .swipeActions {
                    Button("Delete", role: .destructive) { Task { await remove(type.id) } }
                }
            }
            if let message { Text(message).foregroundStyle(Theme.again).listRowBackground(Theme.surface) }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .tabBarScroll()
        .navigationTitle("Note types")
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
    }

    private func reload() async {
        types = ((try? await backend.notetypeUseCounts()) ?? []).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        loaded = true
    }

    private func remove(_ id: Int64) async {
        do { try await backend.removeNotetype(id: id); message = nil } catch { message = error.localizedDescription }
        await reload()
    }
}

/// Edit a note type: fields (add, rename, remove, reorder), card templates and styling.
struct NotetypeEditorScreen: View {
    let backend: Backend
    let notetypeID: Int64
    var sync: SyncModel?
    @Environment(\.dismiss) private var dismiss
    @State private var showRestyle = false
    @State private var showLayout = false
    @State private var notetype: Anki_Notetypes_Notetype?
    @State private var errorMessage: String?
    @State private var duplicates: [[Int64]]?
    @State private var showDuplicates = false

    var body: some View {
        List {
            if let notetype {
                Section("Name") {
                    TextField("Name", text: Binding(
                        get: { self.notetype?.name ?? "" }, set: { self.notetype?.name = $0 }))
                        .listRowBackground(Theme.surface)
                }
                Section("Fields") {
                    ForEach(notetype.fields.indices, id: \.self) { index in
                        TextField("Field name", text: Binding(
                            get: { self.notetype?.fields[index].name ?? "" },
                            set: { self.notetype?.fields[index].name = $0 }))
                            .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    }
                    .onDelete { offsets in
                        if (self.notetype?.fields.count ?? 0) > offsets.count { self.notetype?.fields.remove(atOffsets: offsets) }
                    }
                    .onMove { self.notetype?.fields.move(fromOffsets: $0, toOffset: $1) }
                    Button("Add field", systemImage: "plus") {
                        var field = Anki_Notetypes_Notetype.Field()
                        field.name = "Field \(notetype.fields.count + 1)"
                        field.config.fontName = "Arial"
                        field.config.fontSize = 20
                        self.notetype?.fields.append(field)
                    }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("notetype-add-field")
                }
                Section("Card templates") {
                    ForEach(notetype.templates.indices, id: \.self) { index in
                        NavigationLink(notetype.templates[index].name) {
                            TemplateEditor(template: Binding(
                                get: { self.notetype?.templates[index] ?? .init() },
                                set: { self.notetype?.templates[index] = $0 }))
                        }
                        .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    }
                }
                Section("Styling") {
                    Button("Use Cornhub style", systemImage: "paintbrush") { showRestyle = true }
                        .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                        .accessibilityIdentifier("notetype-restyle")
                    if NotetypeLayout.offered(for: notetype.fields.map(\.name)) {
                        Button("Use Cornhub layout", systemImage: "rectangle.3.group") { showLayout = true }
                            .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                            .accessibilityIdentifier("notetype-layout")
                    }
                    TextEditor(text: Binding(
                        get: { self.notetype?.config.css ?? "" }, set: { self.notetype?.config.css = $0 }))
                        .font(.system(.footnote, design: .monospaced)).frame(minHeight: 160)
                        .scrollContentBackground(.hidden).listRowBackground(Theme.surface)
                        .accessibilityLabel("Card styling CSS")
                }
                Section {
                    Button("Find duplicates") { Task { await findDuplicates(notetype) } }
                        .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                        .accessibilityIdentifier("notetype-duplicates")
                } footer: {
                    Text("Compares the first field of every note of this type.")
                }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(Theme.again).listRowBackground(Theme.surface) }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .tabBarScroll()
        .navigationTitle(notetype?.name ?? "Note type")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }.disabled(notetype == nil)
                    .accessibilityIdentifier("notetype-save")
            }
        }
        .task {
            do { notetype = try await backend.getNotetype(id: notetypeID) } catch {
                errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $showRestyle) {
            NotetypeRestyleSheet(backend: backend, notetypeID: notetypeID, sync: sync) {
                Task { notetype = try? await backend.getNotetype(id: notetypeID) }
            }
        }
        .sheet(isPresented: $showLayout) {
            NotetypeLayoutSheet(backend: backend, notetypeID: notetypeID, sync: sync) {
                Task { notetype = try? await backend.getNotetype(id: notetypeID) }
            }
        }
        .sheet(isPresented: $showDuplicates) {
            DuplicatesSheet(backend: backend, groups: duplicates ?? [])
        }
    }

    private func save() async {
        guard let notetype else { return }
        do { try await backend.updateNotetype(notetype); dismiss() } catch { errorMessage = error.localizedDescription }
    }

    private func findDuplicates(_ notetype: Anki_Notetypes_Notetype) async {
        do {
            duplicates = try await backend.findDuplicates(
                notetypeID: notetype.id, notetypeName: notetype.name, fieldIndex: 0)
            showDuplicates = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct TemplateEditor: View {
    @Binding var template: Anki_Notetypes_Notetype.Template

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $template.name).listRowBackground(Theme.surface)
            }
            Section("Front template") { editor($template.config.qFormat, label: "Front template") }
            Section("Back template") { editor($template.config.aFormat, label: "Back template") }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func editor(_ text: Binding<String>, label: String) -> some View {
        TextEditor(text: text).font(.system(.footnote, design: .monospaced)).frame(minHeight: 140)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .scrollContentBackground(.hidden).listRowBackground(Theme.surface).accessibilityLabel(label)
    }
}

/// Groups of notes whose first field is the same.
struct DuplicatesSheet: View {
    let backend: Backend
    let groups: [[Int64]]
    @Environment(\.dismiss) private var dismiss
    @State private var texts: [Int64: String] = [:]

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Text("No duplicates found.").foregroundStyle(Theme.muted).listRowBackground(Theme.surface)
                }
                ForEach(groups, id: \.self) { group in
                    Section("\(group.count) notes") {
                        ForEach(group, id: \.self) { id in
                            Text(texts[id] ?? "…").lineLimit(2).frame(minHeight: Theme.minTarget, alignment: .leading)
                                .listRowBackground(Theme.surface)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Duplicates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .task {
                for id in groups.flatMap({ $0 }) {
                    if let note = try? await backend.getNote(id: id) { texts[id] = note.fields.joined(separator: " · ") }
                }
            }
        }
    }
}
