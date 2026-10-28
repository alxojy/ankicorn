import SwiftUI

/// Sidebar-style sheet: decks, tags, note types and flags narrow the search.
struct BrowseFilterSheet: View {
    let model: BrowseModel
    @Environment(\.dismiss) private var dismiss
    private static let flagNames = ["Red", "Orange", "Green", "Blue", "Pink", "Turquoise", "Purple"]

    var body: some View {
        NavigationStack {
            List {
                Section("Decks") {
                    ForEach(model.decks, id: \.id) { deck in
                        row(deck.name, selected: model.deck == deck.name) {
                            model.deck = model.deck == deck.name ? nil : deck.name
                        }
                    }
                }
                Section("Flags") {
                    ForEach(1...7, id: \.self) { flag in
                        row(Self.flagNames[flag - 1], selected: model.flag == flag, symbol: "flag.fill") {
                            model.flag = model.flag == flag ? nil : flag
                        }
                    }
                }
                Section("Note types") {
                    ForEach(model.notetypes, id: \.id) { type in
                        row(type.name, selected: model.notetype == type.name) {
                            model.notetype = model.notetype == type.name ? nil : type.name
                        }
                    }
                }
                Section("Tags") {
                    if model.tags.isEmpty { Text("No tags yet").foregroundStyle(Theme.muted) }
                    ForEach(model.tags, id: \.self) { tag in
                        row(tag, selected: model.tag == tag, symbol: "tag") {
                            model.tag = model.tag == tag ? nil : tag
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { Task { await model.clearFilters() } }.disabled(!model.hasFilters)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                        Task { await model.search() }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ title: String, selected: Bool, symbol: String = "square.stack",
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol).foregroundStyle(Theme.muted).accessibilityHidden(true)
                Text(title).foregroundStyle(Theme.text)
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
            }
            .frame(minHeight: Theme.minTarget)
            .contentShape(Rectangle())
        }
        .listRowBackground(Theme.surface)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Parameter sheets for the bulk actions.
struct BrowseActionSheet: View {
    enum Kind: String, Identifiable {
        case deck, addTags, removeTags, reposition, dueDate
        var id: String { rawValue }
    }

    let kind: Kind
    let model: BrowseModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var start = 0
    @State private var step = 1
    @State private var randomize = false
    @State private var shift = false

    var body: some View {
        NavigationStack {
            Form {
                switch kind {
                case .deck:
                    ForEach(model.decks, id: \.id) { deck in
                        Button(deck.name) { run(.changeDeck(deck.id)) }
                            .frame(minHeight: Theme.minTarget, alignment: .leading)
                    }
                case .addTags, .removeTags:
                    TextField("Tags, separated by spaces", text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                case .reposition:
                    Stepper("Start at \(start)", value: $start, in: 0...1_000_000)
                    Stepper("Step \(step)", value: $step, in: 1...1000)
                    Toggle("Randomise order", isOn: $randomize)
                    Toggle("Shift existing cards", isOn: $shift)
                case .dueDate:
                    TextField("Days: 0, 3, or 3-7", text: $text)
                        .keyboardType(.numbersAndPunctuation)
                    Text("Add ! to also change the interval, e.g. 3!").font(.footnote).foregroundStyle(Theme.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                if kind != .deck {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") { apply() }
                            .disabled((kind == .reposition) ? false : text.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var title: String {
        switch kind {
        case .deck: "Change deck"
        case .addTags: "Add tags"
        case .removeTags: "Remove tags"
        case .reposition: "Reposition"
        case .dueDate: "Set due date"
        }
    }

    private func apply() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        switch kind {
        case .deck: break
        case .addTags: run(.addTags(trimmed))
        case .removeTags: run(.removeTags(trimmed))
        case .reposition: run(.reposition(start: UInt32(start), step: UInt32(step), randomize: randomize, shift: shift))
        case .dueDate: run(.setDueDate(trimmed))
        }
    }

    private func run(_ action: BrowseModel.Action) {
        dismiss()
        Task { await model.perform(action) }
    }
}

/// Previewer: the card's question, then its answer, in the same web view as review.
struct CardPreviewSheet: View {
    let backend: Backend
    let cardID: Int64
    @Environment(\.dismiss) private var dismiss
    @State private var card: RenderedCard?
    @State private var showAnswer = false
    @State private var failed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let card {
                    CardWebView(html: showAnswer ? card.answer : card.question, css: card.css)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
                    Button(showAnswer ? "Show question" : "Show answer") { showAnswer.toggle() }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                        .background(Theme.accent, in: Capsule())
                } else if failed {
                    ContentUnavailableView("Could not render this card", systemImage: "exclamationmark.triangle")
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task {
                do { card = try await backend.renderExistingCard(id: cardID) } catch { failed = true }
            }
        }
    }
}

/// Deck scope picker: the deck tree with indented subdecks. Choosing a deck includes its subdecks.
struct DeckScopeSheet: View {
    let model: BrowseModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                row("All decks", depth: 0, selected: model.deck == nil) { model.deck = nil }
                ForEach(model.decks, id: \.id) { deck in
                    let parts = deck.name.components(separatedBy: "::")
                    row(parts.last ?? deck.name, depth: parts.count - 1, selected: model.deck == deck.name) {
                        model.deck = deck.name
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("browse-deck-picker")
    }

    private func row(_ title: String, depth: Int, selected: Bool, choose: @escaping () -> Void) -> some View {
        Button {
            choose()
            dismiss()
            Task { await model.search() }
        } label: {
            HStack {
                Text(title).foregroundStyle(Theme.text).padding(.leading, CGFloat(depth) * 16)
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundStyle(Theme.accent).accessibilityHidden(true) }
            }
            .frame(minHeight: Theme.minTarget)
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
