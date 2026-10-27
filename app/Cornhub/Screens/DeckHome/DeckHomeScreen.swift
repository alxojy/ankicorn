import SwiftUI

/// The Decks tab: date and sync line, due-count hero, stacked bar, Start review and the deck tile grid.
struct DeckHomeScreen: View {
    let model: DeckHomeModel
    @State private var showNote: String?
    @State private var reviewTarget: ReviewTarget?

    var body: some View {
        NavigationStack {
            content
                .background(Theme.bg)
                .navigationDestination(for: DeckTile.self) { DeckOverviewScreen(deck: $0, model: model) }
                .toolbar(.hidden, for: .navigationBar)
        }
        .task { await model.load() }
        .fullScreenCover(item: $reviewTarget, onDismiss: { Task { await model.refresh() } }) { target in
            if let backend = model.backend { ReviewScreen(backend: backend, deckID: target.deckID) }
        }
        .alert(showNote ?? "", isPresented: Binding(get: { showNote != nil }, set: { if !$0 { showNote = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .loading:
            ProgressView("Opening collection").frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("Could not open the collection", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await model.load() } }.frame(minHeight: Theme.minTarget)
            }
        case .loaded where model.decks.isEmpty:
            ContentUnavailableView {
                Label("No decks yet", systemImage: "tray")
            } description: {
                Text("Add a deck to start learning.")
            } actions: {
                Button("Add deck") { showNote = "Adding decks is coming soon." }.frame(minHeight: Theme.minTarget)
            }
        case .loaded:
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    hero
                    StackedBar(new: model.newTotal, learning: model.learningTotal, review: model.reviewTotal)
                    Button {
                        reviewTarget = ReviewTarget(deckID: nil)
                    } label: {
                        Text("Start review").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(Theme.accent)
                    .foregroundStyle(Theme.onAccent)
                    .accessibilityIdentifier("start-review")
                    Text("Decks").font(.inkAnswer).foregroundStyle(Theme.text)
                    DeckGrid(decks: model.decks)
                }
                .padding(.horizontal, 16)
            }
            .refreshable { await model.refresh() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.headline).foregroundStyle(Theme.text)
                HStack(spacing: 6) {
                    Circle().fill(Theme.synced).frame(width: 8, height: 8).accessibilityHidden(true)
                    Text(model.syncStatus).font(.footnote).foregroundStyle(Theme.muted)
                }
            }
            Spacer()
            roundButton("arrow.triangle.2.circlepath", "Sync") { showNote = "Sync arrives in a later phase." }
            roundButton("plus", "Add") { showNote = "Adding cards is coming soon." }
        }
    }

    private func roundButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.text)
                .frame(width: Theme.minTarget, height: Theme.minTarget)
                .background(Theme.control, in: Circle())
        }
        .accessibilityLabel(label)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(model.dueTotal)")
                .font(.display(DisplaySize.dueCount))
                .foregroundStyle(Theme.text)
                .minimumScaleFactor(0.5)
                .accessibilityIdentifier("due-total")
            Text("cards due").font(.title3).foregroundStyle(Theme.text2)
            Text(heroLine).font(.footnote).foregroundStyle(Theme.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var heroLine: String {
        let done = model.studiedToday.isEmpty ? "Nothing studied yet" : model.studiedToday
        return "≈ \(model.estimatedMinutes) min · \(done) · Streak —"
    }
}

/// New / learning / review split of the due cards, with a labelled legend.
struct StackedBar: View {
    let new: Int
    let learning: Int
    let review: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                let total = max(new + learning + review, 1)
                HStack(spacing: 2) {
                    segment(new, total, Theme.new, proxy.size.width)
                    segment(learning, total, Theme.learning, proxy.size.width)
                    segment(review, total, Theme.accent, proxy.size.width)
                }
                .background(Theme.control, in: Capsule())
                .clipShape(Capsule())
            }
            .frame(height: 10)
            HStack(spacing: 16) {
                legend("New", new, Theme.new)
                legend("Learning", learning, Theme.learning)
                legend("Review", review, Theme.accent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(new) new, \(learning) learning, \(review) review")
    }

    @ViewBuilder private func segment(_ value: Int, _ total: Int, _ color: Color, _ width: CGFloat) -> some View {
        if value > 0 { color.frame(width: width * CGFloat(value) / CGFloat(total)) }
    }

    private func legend(_ label: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(value)").font(.caption).foregroundStyle(Theme.text2)
        }
    }
}
