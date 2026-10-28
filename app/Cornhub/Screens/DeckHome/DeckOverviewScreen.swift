import SwiftUI

/// One deck: header, collection card, today's counts, Study, Levels (when there are subdecks), Coming up and rows.
/// Every count comes from the engine; the sections appear only when they apply.
struct DeckOverviewScreen: View {
    let deck: DeckTile
    let model: DeckHomeModel
    @Environment(AppState.self) private var appState
    @State private var overview = DeckOverviewModel()
    @State private var reviewTarget: ReviewTarget?
    @State private var showCustomStudy = false
    @State private var optionsPage: AnkiWebPage?
    @State private var actions = DeckActionState()
    @State private var newSubdeckPrefix: String?
    @State private var buriedCount = 0
    @State private var unburyNotice: String?
    @State private var limitKind: LimitSheet.Kind?
    @State private var openOptionsAfterSheet = false
    @State private var descriptionExpanded = false
    @Environment(\.dismiss) private var dismiss

    private var current: DeckTile { model.tile(for: deck.id) ?? deck }
    private var isParent: Bool { DeckOverviewModel.showsLevels(current) }
    private var studyTotal: Int { DeckOverviewModel.studyTotal(current) }
    private var nothingDue: Bool { studyTotal == 0 }
    private var newCapped: Bool { DeckOverviewModel.isCapped(available: overview.newAvailable, shown: current.newCount) }
    private var reviewCapped: Bool { DeckOverviewModel.isCapped(available: overview.reviewAvailable, shown: current.reviewCount) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if !overview.description.isEmpty { descriptionView }
                CollectionCard(counts: overview.counts, lastStudied: DeckOverviewModel.lastStudiedText(overview.lastStudiedDays))
                todayCard
                studyButton
                if isParent { levels }
                if showsComingUp {
                    Button { appState.openStats(deckID: current.id) } label: { ComingUpCard(forecast: overview.forecast) }
                        .buttonStyle(.plain)
                }
                rows
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
        .task(id: current) {
            buriedCount = await model.buriedCount(for: current)
            if let backend = model.backend { await overview.load(deck: current, backend: backend) }
        }
        .navigationTitle("")
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
        .sheet(
            item: $limitKind,
            onDismiss: {
                if openOptionsAfterSheet {
                    openOptionsAfterSheet = false
                    optionsPage = .deckOptions(deckID: deck.id)
                }
            }
        ) { kind in
            LimitSheet(
                kind: kind,
                available: kind == .new ? overview.newAvailable : overview.reviewAvailable,
                shown: kind == .new ? current.newCount : current.reviewCount
            ) {
                openOptionsAfterSheet = true
                limitKind = nil
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let crumb = DeckOverviewModel.breadcrumb(current) {
                if let parentName = DeckOverviewModel.parentName(current), let parent = model.tile(fullName: parentName) {
                    NavigationLink(value: parent) {
                        Text(crumb).font(.subheadline).foregroundStyle(Theme.text2).lineLimit(1)
                            .frame(minHeight: Theme.minTarget, alignment: .leading)
                    }
                    .accessibilityLabel("Go to \(parent.name)")
                    .accessibilityIdentifier("deck-breadcrumb")
                } else {
                    Text(crumb).font(.subheadline).foregroundStyle(Theme.text2).lineLimit(1)
                }
            }
            HStack(spacing: 12) {
                LevelIcon(deck: current)
                VStack(alignment: .leading, spacing: 2) {
                    Text(current.name)
                        .font(.display(DisplaySize.sectionHeading, relativeTo: .title2))
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("deck-title")
                    if DeckOverviewModel.breadcrumb(current) == nil {
                        Text(DeckOverviewModel.subtitle(current)).font(.subheadline).foregroundStyle(Theme.muted)
                            .accessibilityIdentifier("deck-subtitle")
                    }
                }
            }
        }
    }

    private var descriptionView: some View {
        let text = overview.description
        let long = text.count > 140 || text.contains("\n")
        return VStack(alignment: .leading, spacing: 4) {
            Text(text).font(.subheadline).foregroundStyle(Theme.text2)
                .lineLimit(descriptionExpanded ? nil : 3)
                .accessibilityIdentifier("deck-description")
            if long {
                Button(descriptionExpanded ? "Less" : "More") { descriptionExpanded.toggle() }
                    .font(.subheadline).foregroundStyle(Theme.accent)
                    .frame(minHeight: Theme.minTarget, alignment: .leading)
                    .accessibilityIdentifier("deck-description-more")
            }
        }
    }

    // MARK: Today and Study

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(isParent ? "Today, across all levels" : "Today").inkLabel()
                Spacer(minLength: 8)
                if isParent {
                    Text("Daily limits on").font(.caption).foregroundStyle(Theme.muted)
                }
            }
            HStack(spacing: 8) {
                TodayTile(
                    title: "New", value: current.newCount, color: Theme.new,
                    cappedLine: newCapped ? DeckOverviewModel.cappedLine(available: overview.newAvailable, shown: current.newCount) : nil,
                    identifier: "today-new"
                ) { limitKind = .new }
                TodayTile(title: "Learning", value: current.learningCount, color: Theme.learning, identifier: "today-learning")
                TodayTile(
                    title: "Due", value: current.reviewCount, color: Theme.accent,
                    cappedLine: reviewCapped
                        ? DeckOverviewModel.cappedLine(available: overview.reviewAvailable, shown: current.reviewCount) : nil,
                    identifier: "today-due"
                ) { limitKind = .review }
            }
        }
        .inkCard()
    }

    @ViewBuilder private var studyButton: some View {
        Button {
            reviewTarget = ReviewTarget(deckID: deck.id)
        } label: {
            Text(nothingDue ? "Nothing due today" : isParent ? "Study all · \(studyTotal) cards" : "Study \(current.name) · \(studyTotal) cards")
                .font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
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

    // MARK: Levels, Coming up, rows

    private var levels: some View {
        VStack(alignment: .leading, spacing: 8) {
            LevelsHeader()
            VStack(spacing: 0) {
                ForEach(Array(current.children.enumerated()), id: \.element.id) { index, child in
                    NavigationLink(value: child) { LevelRow(deck: child, counts: overview.levelCounts[child.id], index: index) }
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

    /// Leaf decks always; a parent only when something is coming up.
    private var showsComingUp: Bool { !isParent || overview.forecast.contains { $0 > 0 } }

    private var rows: some View {
        VStack(spacing: 0) {
            DeckActionRow(
                title: "Browse cards", symbol: "rectangle.stack", detail: overview.counts.total.formatted(),
                identifier: "browse-cards-button"
            ) { appState.openBrowse(deckID: current.id) }
            Divider().overlay(Theme.hairline)
            DeckActionRow(title: "Custom study", symbol: "slider.horizontal.3", identifier: "custom-study-button") {
                showCustomStudy = true
            }
            Divider().overlay(Theme.hairline)
            DeckActionRow(title: "Daily limits & options", symbol: "gearshape", identifier: "deck-options-button") {
                optionsPage = .deckOptions(deckID: deck.id)
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile).strokeBorder(Theme.hairline, lineWidth: 1))
        .padding(.bottom, 8)
    }

    @ViewBuilder private var menuItems: some View {
        Section {
            Button { actions.startRename(current) } label: { Label("Rename", systemImage: "pencil") }
                .accessibilityIdentifier("deck-action-rename")
            Button {
                newSubdeckPrefix = DeckOverviewModel.fullName(current) + "::"
            } label: { Label("New subdeck…", systemImage: "rectangle.stack.badge.plus") }
                .accessibilityIdentifier("deck-new-subdeck")
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
        if model.canDelete(current) {
            Section {
                Button(role: .destructive) { actions.deleting = current } label: { Label("Delete", systemImage: "trash") }
                    .accessibilityIdentifier("deck-action-delete")
            }
        }
    }
}
