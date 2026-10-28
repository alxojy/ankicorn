import SwiftUI

/// Name field for a new deck or subdeck. `Parent::Child` makes a subdeck; the engine does the work.
struct NewDeckSheet: View {
    let model: DeckHomeModel
    var initialName = ""
    var onCreated: () -> Void = {}
    @State private var name = ""
    @State private var creating = false
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    private var cleaned: String { DeckHomeModel.cleanedDeckName(name) }
    /// A bare "Parent::" is not a name yet.
    private var incomplete: Bool { cleaned.isEmpty || cleaned.hasSuffix("::") }
    private var taken: Bool { !incomplete && model.nameTaken(cleaned) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New deck").font(.display(DisplaySize.sectionHeading, relativeTo: .title2)).foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            TextField("Deck name", text: $name)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(create)
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.minTarget)
                .background(Theme.control, in: RoundedRectangle(cornerRadius: Theme.Radius.photo))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.photo)
                        .strokeBorder(taken ? Theme.again : Theme.hairline, lineWidth: 1)
                )
                .accessibilityIdentifier("new-deck-field")
            if taken {
                Text("A deck called \u{201C}\(cleaned)\u{201D} already exists")
                    .font(.footnote).foregroundStyle(Theme.again)
                    .accessibilityIdentifier("new-deck-error")
            } else {
                Text("Use :: to make a subdeck, like Travel::Food.")
                    .font(.footnote).foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("new-deck-hint")
            }
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                    .foregroundStyle(Theme.text)
                    .accessibilityIdentifier("new-deck-cancel")
                Button(action: create) {
                    Text("Create").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                        .foregroundStyle(Theme.onAccent)
                        .background(Theme.accent.opacity(incomplete || taken ? 0.4 : 1), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(incomplete || taken || creating)
                .accessibilityIdentifier("new-deck-create")
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.margin)
        .background(Theme.bg)
        .presentationDetents([.medium])
        .onAppear {
            name = initialName
            focused = true
        }
    }

    private func create() {
        guard !incomplete, !taken, !creating else { return }
        creating = true
        Task {
            if await model.createDeck(cleaned) {
                onCreated()
                dismiss()
            }
            creating = false
        }
    }
}
