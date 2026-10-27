import SwiftUI

/// The deck tree exactly as rslib returns it, in the Decks tab. Themed with Ink tokens; the full Decks design comes later.
struct DeckTreeScreen: View {
    let model: DeckTreeModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Decks")
                .background(Theme.bg)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await model.load() }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .loading:
            ProgressView("Opening collection")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView(
                "Could not open the collection", systemImage: "exclamationmark.triangle", description: Text(message))
        case .loaded(let rows) where rows.isEmpty:
            ContentUnavailableView("No decks", systemImage: "tray", description: Text("The collection is empty."))
        case .loaded(let rows):
            List(rows) { row in
                Text(row.name)
                    .foregroundStyle(Theme.text)
                    .listRowBackground(Theme.surface)
                    .padding(.leading, CGFloat(row.level) * 20)
                    .frame(minHeight: 44, alignment: .leading)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(row.fullName)
                    .accessibilityIdentifier("deck-row")
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview("Default") {
    DeckTreeScreen(model: DeckTreeModel(launch: LaunchOptions(seedSample: true, resetCollection: true)))
}

#Preview("Large text") {
    DeckTreeScreen(model: DeckTreeModel(launch: LaunchOptions(seedSample: true, resetCollection: true)))
        .dynamicTypeSize(.accessibility3)
}
