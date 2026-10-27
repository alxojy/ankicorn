import SwiftUI

/// Simple field editor for the current note: one text field per note field.
struct NoteEditorSheet: View {
    @State var note: Anki_Notes_Note
    let onSave: (Anki_Notes_Note) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                ForEach(note.fields.indices, id: \.self) { index in
                    Section {
                        TextField("Field \(index + 1)", text: $note.fields[index], axis: .vertical)
                            .accessibilityLabel("Field \(index + 1)")
                    } header: {
                        Text("Field \(index + 1)").inkLabel()
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(note)
                        dismiss()
                    }
                    .accessibilityIdentifier("note-save")
                }
            }
        }
    }
}
