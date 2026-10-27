import SwiftUI

/// Entry point (from Settings) for filtered decks, tags and note types.
struct ManageScreen: View {
    let backend: Backend?

    var body: some View {
        List {
            if let backend {
                NavigationLink {
                    FilteredDecksScreen(backend: backend)
                } label: {
                    Label("Filtered decks", systemImage: "line.3.horizontal.decrease.circle")
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("manage-filtered")
                NavigationLink {
                    TagsScreen(backend: backend)
                } label: {
                    Label("Tags", systemImage: "tag")
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("manage-tags")
                NavigationLink {
                    NotetypesScreen(backend: backend)
                } label: {
                    Label("Note types", systemImage: "rectangle.stack")
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("manage-notetypes")
            } else {
                Text("The collection is not open yet.").foregroundStyle(Theme.muted).listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Manage")
        .navigationBarTitleDisplayMode(.inline)
    }
}
