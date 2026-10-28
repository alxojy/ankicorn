import SwiftUI

/// The Browse tab: search, sort, filter, preview, edit and bulk actions.
struct BrowseScreen: View {
    let backend: Backend?

    var body: some View {
        if let backend {
            BrowseContent(model: BrowseModel(backend: backend))
        } else {
            PlaceholderScreen(title: "Browse", symbol: "magnifyingglass", message: "Open a collection to browse it.")
        }
    }
}

private struct IdentifiedID: Identifiable { let id: Int64 }
private struct IdentifiedNote: Identifiable {
    let note: Anki_Notes_Note
    var id: Int64 { note.id }
}

private struct BrowseContent: View {
    @State var model: BrowseModel
    @State private var showFilters = false
    @State private var editing: IdentifiedNote?
    @State private var previewing: IdentifiedID?
    @State private var activeSheet: BrowseActionSheet.Kind?
    @State private var confirmDelete = false
    @State private var showReplace = false
    @State private var showDeckPicker = false
    @State private var pendingDelete: PendingDelete?
    @State private var undoVisible = false
    @Environment(AppState.self) private var appState

    private struct PendingDelete {
        let notes: Int
        let cards: Int
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                deckChip
                if model.hasOtherFilters { filterChips }
                content
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    if undoVisible { undoToast }
                    if model.selecting { actionBar }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.bottom, 8)
            }
            .animation(.spring(duration: 0.3), value: model.selecting)
            .onChange(of: model.selecting) { _, _ in syncTabBar() }
            .onChange(of: undoVisible) { _, _ in syncTabBar() }
            .onDisappear { appState.hideTabBar = false }
            .onChange(of: model.deck) { _, value in appState.lastBrowseDeck = value }
            .onChange(of: appState.browseDeckID) { _, _ in Task { await consumeScopeRequest() } }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search cards")
            .onSubmit(of: .search) { Task { await model.searchNow() } }
            .onChange(of: model.query) { _, _ in model.queryDidChange() }
            .toolbar { toolbar }
            .task {
                model.deck = appState.lastBrowseDeck
                await model.load()
                await consumeScopeRequest()
            }
            .sheet(isPresented: $showDeckPicker) { DeckScopeSheet(model: model) }
            .sheet(isPresented: $showFilters) { BrowseFilterSheet(model: model) }
            .sheet(isPresented: $showReplace) { FindReplaceSheet(model: model) }
            .sheet(item: $activeSheet) { kind in BrowseActionSheet(kind: kind, model: model) }
            .sheet(item: $previewing) { item in CardPreviewSheet(backend: model.backend, cardID: item.id) }
            .fullScreenCover(item: $editing) { item in
                NoteEditorScreen(backend: model.backend, mode: .edit(item.note)) { _ in
                    Task { await model.search() }
                }
            }
            .confirmationDialog(deleteTitle, isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        await model.perform(.delete)
                        showUndo()
                    }
                }
                .accessibilityIdentifier("browse-delete-confirm")
            } message: {
                Text(model.notesMode ? "The notes and all of their cards are removed."
                     : "Deleting a card removes its note and all of the note's cards.")
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: { Text(model.errorMessage ?? "") }
            .sensoryFeedback(.success, trigger: model.changeCount)
        }
    }

    private var deleteTitle: String {
        guard let pending = pendingDelete else { return "Delete?" }
        return "Delete \(pending.notes) \(pending.notes == 1 ? "note" : "notes") (\(pending.cards) \(pending.cards == 1 ? "card" : "cards"))?"
    }

    private func syncTabBar() { appState.hideTabBar = model.selecting || undoVisible }

    private func requestDelete() {
        Task {
            let summary = await model.deleteSummary()
            pendingDelete = PendingDelete(notes: summary.notes, cards: summary.cards)
            confirmDelete = true
        }
    }

    private func consumeScopeRequest() async {
        guard let id = appState.browseDeckID else { return }
        appState.browseDeckID = nil
        await model.scope(toDeckID: id)
    }

    private func showUndo() {
        guard model.deletedNotice != nil else { return }
        undoVisible = true
        Task {
            try? await Task.sleep(for: .seconds(8))
            undoVisible = false
        }
    }

    private var undoToast: some View {
        HStack {
            Text(model.deletedNotice ?? "Deleted").font(.inkLabel).foregroundStyle(Theme.text)
            Spacer()
            Button("Undo") {
                undoVisible = false
                Task { await model.undoLast() }
            }
            .font(.inkLabel.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
            .accessibilityIdentifier("browse-undo")
        }
        .padding(.horizontal, 16)
        .glassEffect(.regular.tint(Theme.bg.opacity(0.6)), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var deckChip: some View {
        HStack {
            Button { showDeckPicker = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack").accessibilityHidden(true)
                    Text(model.deck.map { $0.components(separatedBy: "::").last ?? $0 } ?? "All decks")
                    Image(systemName: "chevron.down").font(.caption2).foregroundStyle(Theme.muted)
                        .accessibilityHidden(true)
                }
                .font(.inkLabel)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.minTarget)
                .background(Theme.raised, in: Capsule())
            }
            .accessibilityLabel("Deck: \(model.deck ?? "All decks")")
            .accessibilityIdentifier("browse-deck-chip")
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var modePicker: some View {
        Picker("Show", selection: $model.notesMode) {
            Text("Cards").tag(false)
            Text("Notes").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityIdentifier("browse-mode")
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                                if let tag = model.tag { chip(tag, "tag") { model.tag = nil } }
                if let notetype = model.notetype { chip(notetype, "doc.text") { model.notetype = nil } }
                if let flag = model.flag { chip("Flag \(flag)", "flag.fill") { model.flag = nil } }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private func chip(_ title: String, _ symbol: String, remove: @escaping () -> Void) -> some View {
        Button {
            remove()
            Task { await model.search() }
        } label: {
            Label(title, systemImage: symbol)
                .font(.inkLabel)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.minTarget)
                .background(Theme.raised, in: Capsule())
        }
        .accessibilityLabel("Remove filter \(title)")
    }

    @ViewBuilder private var content: some View {
        if model.isLoading && model.ids.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.ids.isEmpty {
            ContentUnavailableView("No matches", systemImage: "magnifyingglass",
                                   description: Text("Try a different search or clear the filters."))
        } else {
            Text(model.countLine)
                .font(.inkLabel).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .accessibilityIdentifier("browse-count")
            List {
                ForEach(model.ids, id: \.self) { id in row(id) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
        }
    }

    private func row(_ id: Int64) -> some View {
        let cells = model.rows[id]?.cells.map(\.text) ?? []
        let title = cells.first.map(Self.plain) ?? " "
        // Cards mode shows question, answer, deck: the secondary line is the answer column only.
        let rest = model.notesMode ? Array(cells.dropFirst()) : Array(cells.dropFirst().prefix(1))
        let subtitle = rest.map(Self.plain).filter { !$0.isEmpty }.joined(separator: " · ")
        let selected = model.selecting && model.selection.contains(id)
        return Button {
            if model.selecting {
                model.toggle(id)
            } else {
                Task { editing = await model.note(for: id).map(IdentifiedNote.init) }
            }
        } label: {
            HStack(spacing: 12) {
                if model.selecting {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? Theme.accent : Theme.muted)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body).foregroundStyle(Theme.text).lineLimit(2)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.footnote).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let color = model.rows[id].flatMap({ Self.marker($0.color) }) {
                    Circle().fill(color).frame(width: 10, height: 10).accessibilityHidden(true)
                }
            }
            .frame(minHeight: Theme.minTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selected ? Theme.raised : Theme.surface)
        .task(id: model.rows[id] == nil) { await model.loadRow(id) }
        .contextMenu {
            Button("Preview", systemImage: "eye") {
                Task { previewing = await model.previewCardID(for: id).map(IdentifiedID.init) }
            }
        }
        .swipeActions(edge: .leading) {
            Button("Preview", systemImage: "eye") {
                Task { previewing = await model.previewCardID(for: id).map(IdentifiedID.init) }
            }.tint(Theme.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                model.selection = [id]
                requestDelete()
            }
            .accessibilityIdentifier("browse-row-delete")
        }
        .accessibilityLabel("\(title). \(subtitle)\(selected ? ". Selected" : "")")
        .accessibilityIdentifier("browse-row")
    }

    static func plain(_ html: String) -> String {
        html.replacingOccurrences(of: "(<br\\s*/?>|</div>|</p>|\u{1f})+", with: " · ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s{2,}", with: " · ", options: .regularExpression)
            .replacingOccurrences(of: "\\s*·\\s*(·\\s*)*", with: " · ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ·\n\t"))
    }

    static func marker(_ color: Anki_Search_BrowserRow.Color) -> Color? {
        switch color {
        case .suspended: Theme.learning
        case .marked: Theme.accent
        case .flagRed: Theme.again
        case .flagGreen: Theme.easy
        case .flagBlue: Theme.new
        case .flagOrange, .flagPink, .flagTurquoise, .flagPurple, .buried: Theme.text2
        case .default, .UNRECOGNIZED: nil
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(model.selecting ? "Done" : "Select") {
                model.selecting.toggle()
                if !model.selecting { model.selection = [] }
            }
            .accessibilityIdentifier("browse-select")
        }
        if model.selecting {
            ToolbarItem(placement: .topBarLeading) {
                Button(model.selection.count == model.ids.count ? "Select none" : "Select all") {
                    model.selection = model.selection.count == model.ids.count ? [] : Set(model.ids)
                }
                .accessibilityIdentifier("browse-select-all")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Picker("Sort by", selection: Binding(get: { model.sortKey }, set: { key in
                    model.sortKey = key
                    Task { await model.search() }
                })) {
                    Text("Default").tag("")
                    ForEach(model.sortableColumns, id: \.key) { column in
                        Text(model.label(column)).tag(column.key)
                    }
                }
                Toggle("Reverse order", isOn: Binding(get: { model.reverse }, set: { value in
                    model.reverse = value
                    Task { await model.search() }
                }))
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort")
            Button {
                showFilters = true
            } label: {
                Label("Filter", systemImage: model.hasFilters
                      ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel("Filter")
            .accessibilityIdentifier("browse-filter")
        }
    }

    private var actionBar: some View {
        let none = model.selection.isEmpty
        return HStack(spacing: 4) {
            Text("\(model.selection.count)").font(.inkLabel).foregroundStyle(Theme.muted)
                .frame(minWidth: Theme.minTarget)
            Spacer()
            Menu {
                Button("Change deck", systemImage: "square.stack") { activeSheet = .deck }
                Button("Add tags", systemImage: "tag") { activeSheet = .addTags }
                Button("Remove tags", systemImage: "tag.slash") { activeSheet = .removeTags }
                Button("Reposition", systemImage: "list.number") { activeSheet = .reposition }
                Button("Set due date", systemImage: "calendar") { activeSheet = .dueDate }
                Button("Forget (reset to new)", systemImage: "arrow.counterclockwise") {
                    Task { await model.perform(.forget) }
                }
                Button("Find and replace", systemImage: "magnifyingglass") { showReplace = true }
                Button("Suspend", systemImage: "pause.circle") { Task { await model.perform(.suspend(true)) } }
                Button("Unsuspend", systemImage: "play.circle") { Task { await model.perform(.suspend(false)) } }
            } label: {
                Label("Actions", systemImage: "ellipsis.circle")
                    .frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
            }
            .disabled(none)
            .accessibilityIdentifier("browse-actions")
            Button(role: .destructive) {
                requestDelete()
            } label: {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
            }
            .disabled(none)
            .accessibilityIdentifier("browse-delete")
        }
        .padding(.horizontal, 16)
        .glassEffect(.regular.tint(Theme.bg.opacity(0.6)), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview("Default") {
    BrowseScreen(backend: nil)
}
