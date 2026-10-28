import SwiftUI

/// Lists filtered decks with rebuild and empty, and creates new ones.
struct FilteredDecksScreen: View {
    struct Entry: Identifiable {
        let id: Int64
        let name: String
    }

    let backend: Backend
    @State private var decks: [Entry] = []
    @State private var loaded = false
    @State private var editing: EditTarget?
    @State private var message: String?

    struct EditTarget: Identifiable {
        let id: Int64
    }

    var body: some View {
        List {
            if loaded && decks.isEmpty {
                Text("No filtered decks yet. Create one to study cards from a search.")
                    .foregroundStyle(Theme.muted).listRowBackground(Theme.surface)
            }
            ForEach(decks) { deck in
                HStack {
                    Text(deck.name).foregroundStyle(Theme.text)
                    Spacer()
                    Menu {
                        Button("Edit", systemImage: "pencil") { editing = EditTarget(id: deck.id) }
                        Button("Rebuild", systemImage: "arrow.clockwise") { Task { await rebuild(deck) } }
                        Button("Empty", systemImage: "tray") { Task { await empty(deck) } }
                    } label: {
                        Image(systemName: "ellipsis.circle").frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
                    }
                    .accessibilityLabel("Actions for \(deck.name)")
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
            }
            if let message { Text(message).foregroundStyle(Theme.muted).listRowBackground(Theme.surface) }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .tabBarScroll()
        .navigationTitle("Filtered decks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { editing = EditTarget(id: 0) } label: { Label("New filtered deck", systemImage: "plus") }
                .accessibilityIdentifier("filtered-new")
        }
        .task { await load() }
        .sheet(item: $editing) { target in
            FilteredDeckSheet(backend: backend, deckID: target.id) { Task { await load() } }
        }
    }

    private func load() async {
        var found: [Entry] = []
        if let tree = try? await backend.deckTree() {
            var stack = tree.children
            while let node = stack.popLast() {
                stack.append(contentsOf: node.children)
                // Only filtered decks load as filtered; the engine refuses normal ones.
                if (try? await backend.filteredDeckForUpdate(deckID: node.deckID)) != nil, node.deckID != 0 {
                    found.append(Entry(id: node.deckID, name: node.name))
                }
            }
        }
        decks = found.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        loaded = true
    }

    private func rebuild(_ deck: Entry) async {
        do { try await backend.rebuildFilteredDeck(deckID: deck.id); message = "Rebuilt \(deck.name)." } catch {
            message = error.localizedDescription
        }
    }

    private func empty(_ deck: Entry) async {
        do { try await backend.emptyFilteredDeck(deckID: deck.id); message = "Emptied \(deck.name)." } catch {
            message = error.localizedDescription
        }
    }
}

/// Create or edit one filtered deck: name, search, limit, order and rescheduling.
struct FilteredDeckSheet: View {
    let backend: Backend
    let deckID: Int64
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var deck: Anki_Decks_FilteredDeckForUpdate?
    @State private var errorMessage: String?

    private static let orders: [(String, Anki_Decks_Deck.Filtered.SearchTerm.Order)] = [
        ("Oldest reviewed first", .oldestReviewedFirst), ("Random", .random),
        ("Increasing intervals", .intervalsAscending), ("Decreasing intervals", .intervalsDescending),
        ("Most lapses", .lapses), ("Order added", .added), ("Order due", .due),
        ("Latest added first", .reverseAdded), ("Relative overdueness", .relativeOverdueness),
    ]

    var body: some View {
        NavigationStack {
            Form {
                if deck != nil {
                    TextField("Name", text: bind(\.name)).listRowBackground(Theme.card)
                        .accessibilityIdentifier("filtered-name")
                    TextField("Search", text: term(\.search)).textInputAutocapitalization(.never)
                        .autocorrectionDisabled().listRowBackground(Theme.card)
                        .accessibilityIdentifier("filtered-search")
                    Stepper("Limit: \(Int(limit))", value: limitBinding, in: 1...99999, step: 50)
                        .listRowBackground(Theme.card)
                    Picker("Order", selection: orderBinding) {
                        ForEach(Self.orders, id: \.0) { Text($0.0).tag($0.1) }
                    }
                    .listRowBackground(Theme.card)
                    Toggle("Reschedule cards based on my answers", isOn: rescheduleBinding)
                        .listRowBackground(Theme.card)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(Theme.again) }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(deckID == 0 ? "New filtered deck" : "Edit filtered deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Build") { Task { await save() } }.disabled(deck == nil)
                        .accessibilityIdentifier("filtered-build")
                }
            }
            .task {
                do { deck = try await backend.filteredDeckForUpdate(deckID: deckID) } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var limit: UInt32 { deck?.config.searchTerms.first?.limit ?? 100 }

    private func bind(_ path: WritableKeyPath<Anki_Decks_FilteredDeckForUpdate, String>) -> Binding<String> {
        Binding(get: { deck?[keyPath: path] ?? "" }, set: { deck?[keyPath: path] = $0 })
    }

    private func term(_ path: WritableKeyPath<Anki_Decks_Deck.Filtered.SearchTerm, String>) -> Binding<String> {
        Binding(
            get: { deck?.config.searchTerms.first?[keyPath: path] ?? "" },
            set: { value in
                if deck?.config.searchTerms.isEmpty ?? true { deck?.config.searchTerms = [.init()] }
                deck?.config.searchTerms[0][keyPath: path] = value
            })
    }

    private var limitBinding: Binding<UInt32> {
        Binding(
            get: { limit },
            set: { value in
                if deck?.config.searchTerms.isEmpty ?? true { deck?.config.searchTerms = [.init()] }
                deck?.config.searchTerms[0].limit = value
            })
    }

    private var orderBinding: Binding<Anki_Decks_Deck.Filtered.SearchTerm.Order> {
        Binding(
            get: { deck?.config.searchTerms.first?.order ?? .oldestReviewedFirst },
            set: { value in
                if deck?.config.searchTerms.isEmpty ?? true { deck?.config.searchTerms = [.init()] }
                deck?.config.searchTerms[0].order = value
            })
    }

    private var rescheduleBinding: Binding<Bool> {
        Binding(get: { deck?.config.reschedule ?? true }, set: { deck?.config.reschedule = $0 })
    }

    private func save() async {
        guard var deck else { return }
        if deck.config.searchTerms.first?.limit == 0 { deck.config.searchTerms[0].limit = 100 }
        do {
            try await backend.saveFilteredDeck(deck)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
