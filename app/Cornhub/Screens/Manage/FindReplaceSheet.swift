import SwiftUI

/// Find and replace in the notes selected in Browse, using the engine's `find_and_replace`.
struct FindReplaceSheet: View {
    let model: BrowseModel
    @Environment(\.dismiss) private var dismiss
    @State private var find = ""
    @State private var replacement = ""
    @State private var field = ""
    @State private var regex = false
    @State private var matchCase = false
    @State private var result: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Find", text: $find).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .listRowBackground(Theme.card).accessibilityIdentifier("replace-find")
                TextField("Replace with", text: $replacement).textInputAutocapitalization(.never)
                    .autocorrectionDisabled().listRowBackground(Theme.card).accessibilityIdentifier("replace-with")
                TextField("Field name (empty for all fields)", text: $field).textInputAutocapitalization(.never)
                    .autocorrectionDisabled().listRowBackground(Theme.card)
                Toggle("Treat input as regular expression", isOn: $regex).listRowBackground(Theme.card)
                Toggle("Match case", isOn: $matchCase).listRowBackground(Theme.card)
                if let result { Text(result).foregroundStyle(Theme.muted) }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Find and replace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Replace") { Task { await run() } }.disabled(find.isEmpty)
                        .accessibilityIdentifier("replace-run")
                }
            }
        }
    }

    private func run() async {
        do {
            let ids = try await model.selectedNoteIDs()
            let count = try await model.backend.findAndReplace(
                noteIDs: ids, search: find, replacement: replacement, regex: regex, matchCase: matchCase, field: field)
            result = "\(count) notes updated."
            await model.search()
        } catch {
            result = error.localizedDescription
        }
    }
}
