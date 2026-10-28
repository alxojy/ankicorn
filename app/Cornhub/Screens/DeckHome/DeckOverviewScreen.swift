import SwiftUI

/// One deck: today's counts from the engine, a Study button, and a nested grid for subdecks.
struct DeckOverviewScreen: View {
    let deck: DeckTile
    let model: DeckHomeModel
    @Environment(AppState.self) private var appState
    @State private var reviewTarget: ReviewTarget?
    @State private var showCustomStudy = false
    @State private var optionsPage: AnkiWebPage?
    @State private var actions = DeckActionState()
    @State private var newSubdeckPrefix: String?
    @State private var buriedCount = 0
    @State private var unburyNotice: String?
    @Environment(\.dismiss) private var dismiss

    private var current: DeckTile { model.tile(for: deck.id) ?? deck }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                studyButton
                if !current.children.isEmpty { subdecks }
                if let unburyNotice {
                    Text(unburyNotice)
                        .font(.footnote)
                        .foregroundStyle(Theme.text2)
                        .accessibilityIdentifier("unbury-notice")
                }
            }
            .padding(.horizontal, 16)
        }
        .tabBarScroll()
        .background(Theme.bg)
        .task { buriedCount = await model.buriedCount(for: current) }
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu { menuItems } label: {
                    Image(systemName: "ellipsis.circle").frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
                }
                .accessibilityLabel("Deck actions")
                .accessibilityIdentifier("deck-actions-menu")
            }
        }
        .deckActionDialogs(model: model, state: $actions) {
            if model.deletedNotice != nil { dismiss() }
        }
        .fullScreenCover(item: $reviewTarget, onDismiss: { Task { await model.refresh() } }) { target in
            if let backend = model.backend { ReviewScreen(backend: backend, deckID: target.deckID) }
        }
        .sheet(isPresented: $showCustomStudy) {
            if let backend = model.backend {
                CustomStudySheet(backend: backend, deckID: deck.id) {
                    Task {
                        await model.refresh()
                    }
                }
            }
        }
        .sheet(isPresented: Binding(get: { newSubdeckPrefix != nil }, set: { if !$0 { newSubdeckPrefix = nil } })) {
            NewDeckSheet(model: model, initialName: newSubdeckPrefix ?? "")
        }
        .sheet(item: $optionsPage, onDismiss: { Task { await model.refresh() } }) { page in
            if let backend = model.backend { AnkiWebSheet(page: page, backend: backend) }
        }
    }

    private var nothingDue: Bool {
        current.newCount + current.learningCount + current.reviewCount == 0
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("\(current.totalCards) cards").foregroundStyle(Theme.muted)
            Text("·").foregroundStyle(Theme.muted)
            CountsLine(new: current.newCount, learning: current.learningCount, review: current.reviewCount)
        }
        .font(.subheadline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(current.totalCards) cards: \(current.newCount) new, \(current.learningCount) learning, \(current.reviewCount) review")
        .accessibilityIdentifier("deck-summary")
    }

    @ViewBuilder private var studyButton: some View {
        Button {
            reviewTarget = ReviewTarget(deckID: deck.id)
        } label: {
            Text(nothingDue ? "Nothing due" : "Study").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .foregroundStyle(Theme.onAccent)
        .disabled(nothingDue)
        .accessibilityIdentifier("study-button")
        if nothingDue {
            Button("Custom study") { showCustomStudy = true }
                .font(.subheadline)
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                .accessibilityIdentifier("custom-study-link")
        }
    }

    @ViewBuilder private var menuItems: some View {
        Section {
            Button { showCustomStudy = true } label: { Label("Custom study", systemImage: "slider.horizontal.3") }
                .accessibilityIdentifier("custom-study-button")
            if buriedCount > 0 {
                Button {
                    Task {
                        if let count = await model.unbury(current) {
                            buriedCount = await model.buriedCount(for: current)
                            unburyNotice = "Unburied \(count) \(count == 1 ? "card" : "cards")"
                        }
                    }
                } label: { Label("Unbury (\(buriedCount))", systemImage: "tray.and.arrow.up") }
                    .accessibilityIdentifier("unbury-button")
            }
        }
        Section {
            Button { appState.openBrowse(deckID: deck.id) } label: { Label("Browse cards", systemImage: "rectangle.stack") }
                .accessibilityIdentifier("browse-cards-button")
            Button { optionsPage = .deckOptions(deckID: deck.id) } label: { Label("Deck options", systemImage: "gearshape") }
                .accessibilityIdentifier("deck-options-button")
            Button { actions.startRename(current) } label: { Label("Rename", systemImage: "pencil") }
                .accessibilityIdentifier("deck-action-rename")
            Button {
                newSubdeckPrefix = (current.fullName.isEmpty ? current.name : current.fullName) + "::"
            } label: { Label("New subdeck…", systemImage: "rectangle.stack.badge.plus") }
                .accessibilityIdentifier("deck-new-subdeck")
        }
        if model.canDelete(current) {
            Section {
                Button(role: .destructive) { actions.deleting = current } label: { Label("Delete", systemImage: "trash") }
                    .accessibilityIdentifier("deck-action-delete")
            }
        }
    }

    private var subdecks: some View {
        VStack(spacing: 0) {
            ForEach(Array(current.children.enumerated()), id: \.element.id) { index, child in
                NavigationLink(value: child) { SubdeckRow(deck: child, index: index) }
                    .buttonStyle(.plain)
                    .contextMenu { DeckActionItems(model: model, deck: child, state: $actions) }
                    .accessibilityAction(named: "Rename") { actions.startRename(child) }
                    .accessibilityAction(named: "Options") { actions.optionsPage = .deckOptions(deckID: child.id) }
                    .accessibilityAction(named: "Delete") { if model.canDelete(child) { actions.deleting = child } }
                if index < current.children.count - 1 { Divider().overlay(Theme.hairline) }
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile).strokeBorder(Theme.hairline, lineWidth: 1))
    }
}

/// Compact subdeck row: small glyph, name, coloured due counts, chevron.
struct SubdeckRow: View {
    let deck: DeckTile
    var index = 0

    private var glyphColor: Color { [Theme.new, Theme.learning, Theme.synced, Theme.again][index % 4] }

    var body: some View {
        HStack(spacing: 12) {
            Text(deck.glyph)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(glyphColor)
                .minimumScaleFactor(0.5)
                .frame(width: 28)
            Text(deck.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Spacer(minLength: 8)
            CountsLine(new: deck.newCount, learning: deck.learningCount, review: deck.reviewCount)
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: Theme.minTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(deck.accessibilityLabel)
        .accessibilityIdentifier("subdeck-row")
    }
}
