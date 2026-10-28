import SwiftUI

/// Rename / Delete / Options for a deck: the context menu content for a tile, plus the dialogs they open.
struct DeckActionState {
    var renaming: DeckTile?
    var renameText = ""
    var deleting: DeckTile?
    var optionsPage: AnkiWebPage?

    mutating func startRename(_ deck: DeckTile) {
        renameText = deck.fullName.isEmpty ? deck.name : deck.fullName
        renaming = deck
    }
}

private struct DeckActionDialogs: ViewModifier {
    let model: DeckHomeModel
    @Binding var state: DeckActionState
    var onDeleted: () -> Void = {}

    func body(content: Content) -> some View {
        content
            .alert("Rename deck", isPresented: Binding(get: { state.renaming != nil }, set: { if !$0 { state.renaming = nil } })) {
                TextField("Deck name", text: $state.renameText).accessibilityIdentifier("deck-rename-field")
                Button("Cancel", role: .cancel) {}
                Button("Rename") {
                    guard let deck = state.renaming else { return }
                    let name = state.renameText
                    Task { await model.rename(deck, to: name) }
                }
                .accessibilityIdentifier("deck-rename-confirm")
            } message: {
                Text("Use :: to make a subdeck.")
            }
            .confirmationDialog(
                "Delete \u{201C}\(state.deleting?.name ?? "")\u{201D}?",
                isPresented: Binding(get: { state.deleting != nil }, set: { if !$0 { state.deleting = nil } }),
                titleVisibility: .visible, presenting: state.deleting
            ) { deck in
                Button("Delete Deck", role: .destructive) {
                    Task {
                        await model.delete(deck)
                        onDeleted()
                    }
                }
                .accessibilityIdentifier("deck-delete-confirm")
                Button("Cancel", role: .cancel) {}
            } message: { deck in
                Text("Its \(deck.totalCards) cards and any subdecks will be deleted. You can undo this right away.")
            }
            .alert(
                "Could not change the deck",
                isPresented: Binding(get: { model.actionError != nil }, set: { if !$0 { model.actionError = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.actionError ?? "")
            }
            .sheet(item: $state.optionsPage, onDismiss: { Task { await model.refresh() } }) { page in
                if let backend = model.backend { AnkiWebSheet(page: page, backend: backend) }
            }
    }
}

extension View {
    func deckActionDialogs(model: DeckHomeModel, state: Binding<DeckActionState>, onDeleted: @escaping () -> Void = {}) -> some View {
        modifier(DeckActionDialogs(model: model, state: state, onDeleted: onDeleted))
    }
}

/// Menu items shared by the tile context menu, the overview menu and the VoiceOver actions.
struct DeckActionItems: View {
    let model: DeckHomeModel
    let deck: DeckTile
    @Binding var state: DeckActionState

    var body: some View {
        Button { state.startRename(deck) } label: { Label("Rename", systemImage: "pencil") }
            .accessibilityIdentifier("deck-action-rename")
        Button { state.optionsPage = .deckOptions(deckID: deck.id) } label: { Label("Options", systemImage: "gearshape") }
            .accessibilityIdentifier("deck-action-options")
        if model.canDelete(deck) {
            Button(role: .destructive) { state.deleting = deck } label: { Label("Delete", systemImage: "trash") }
                .accessibilityIdentifier("deck-action-delete")
        }
    }
}

/// "Deleted HSK 2 · Undo", shown for a few seconds after a deck is deleted.
struct DeckUndoToast: View {
    let notice: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(notice).font(.inkLabel).foregroundStyle(Theme.text).accessibilityIdentifier("deck-deleted-notice")
            Spacer()
            Button("Undo", action: onUndo)
                .font(.inkLabel.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
                .accessibilityIdentifier("deck-undo")
        }
        .padding(.horizontal, 16)
        .glassEffect(.regular.tint(Theme.bg.opacity(0.6)), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .padding(.horizontal, Theme.margin)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
