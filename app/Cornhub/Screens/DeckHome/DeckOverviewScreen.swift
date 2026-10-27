import SwiftUI

/// One deck: today's counts from the engine, a Study button, and a nested grid for subdecks.
struct DeckOverviewScreen: View {
    let deck: DeckTile
    let model: DeckHomeModel
    @State private var counts: (new: Int, review: Int)?
    @State private var reviewTarget: ReviewTarget?
    @State private var showCustomStudy = false
    @State private var optionsPage: AnkiWebPage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Text(deck.glyph)
                        .font(.display(DisplaySize.hanzi, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.accent)
                    Text("\(deck.totalCards) cards").foregroundStyle(Theme.muted)
                }
                HStack(spacing: 12) {
                    stat("New", counts?.new ?? deck.newCount, Theme.new)
                    stat("Learning", deck.learningCount, Theme.learning)
                    stat("Review", counts?.review ?? deck.reviewCount, Theme.accent)
                }
                Button {
                    reviewTarget = ReviewTarget(deckID: deck.id)
                } label: {
                    Text("Study").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .foregroundStyle(Theme.onAccent)
                .accessibilityIdentifier("study-button")
                HStack(spacing: 12) {
                    Button { showCustomStudy = true } label: {
                        Label("Custom study", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                    }
                    .accessibilityIdentifier("custom-study-button")
                    Button {
                        Task {
                            try? await model.backend?.unburyDeck(id: deck.id)
                            counts = await model.counts(for: deck.id)
                            await model.refresh()
                        }
                    } label: {
                        Label("Unbury", systemImage: "tray.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                    }
                    .accessibilityIdentifier("unbury-button")
                }
                .buttonStyle(.bordered)
                .tint(Theme.text2)
                Button { optionsPage = .deckOptions(deckID: deck.id) } label: {
                    Label("Deck options", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                }
                .buttonStyle(.bordered)
                .tint(Theme.text2)
                .accessibilityIdentifier("deck-options-button")
                if !deck.children.isEmpty { subdecks }
            }
            .padding(.horizontal, 16)
        }
        .background(Theme.bg)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $reviewTarget, onDismiss: { Task { await model.refresh() } }) { target in
            if let backend = model.backend { ReviewScreen(backend: backend, deckID: target.deckID) }
        }
        .sheet(isPresented: $showCustomStudy) {
            if let backend = model.backend {
                CustomStudySheet(backend: backend, deckID: deck.id) {
                    Task {
                        counts = await model.counts(for: deck.id)
                        await model.refresh()
                    }
                }
            }
        }
        .sheet(item: $optionsPage, onDismiss: { Task { counts = await model.counts(for: deck.id); await model.refresh() } }) { page in
            if let backend = model.backend { AnkiWebSheet(page: page, backend: backend) }
        }
        .task { counts = await model.counts(for: deck.id) }
    }

    @ViewBuilder private var subdecks: some View {
        Button {
            Task { await model.setCollapsed(deck.id, !deck.collapsed) }
        } label: {
            HStack {
                Text("Subdecks").inkLabel()
                Spacer()
                Image(systemName: deck.collapsed ? "chevron.down" : "chevron.up")
                    .foregroundStyle(Theme.text2)
            }
            .frame(minHeight: Theme.minTarget)
        }
        .accessibilityLabel(deck.collapsed ? "Expand subdecks" : "Collapse subdecks")
        if !deck.collapsed { DeckGrid(decks: deck.children) }
    }

    private func stat(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.display(28, relativeTo: .title)).foregroundStyle(value == 0 ? Theme.zero : color)
            Text(label).inkLabel()
        }
        .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        .padding(.vertical, 12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
