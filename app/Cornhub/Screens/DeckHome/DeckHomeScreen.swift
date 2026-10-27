import SwiftUI
import UniformTypeIdentifiers

/// The Decks tab: date and sync line, due-count hero, stacked bar, Start review and the deck tile grid.
struct DeckHomeScreen: View {
    let model: DeckHomeModel
    let sync: SyncModel
    @State private var showNote: String?
    @State private var addingCard = false
    @State private var reviewTarget: ReviewTarget?
    @State private var pickingFile = false
    @State private var showLogin = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            content
                .background(Theme.bg)
                .navigationDestination(for: DeckTile.self) { DeckOverviewScreen(deck: $0, model: model) }
                .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $reviewTarget, onDismiss: { Task { await model.refresh() } }) { target in
            if let backend = model.backend { ReviewScreen(backend: backend, deckID: target.deckID) }
        }
        .fullScreenCover(isPresented: $addingCard, onDismiss: { Task { await model.refresh() } }) {
            if let backend = model.backend { NoteEditorScreen(backend: backend, mode: .add) }
        }
        .fileImporter(isPresented: $pickingFile, allowedContentTypes: UTType.ankiPackages) { result in
            if case .success(let url) = result { Task { await model.importPackage(url) } }
        }
        .sheet(isPresented: Binding(get: { model.importState != .idle }, set: { if !$0 { model.dismissImport() } })) {
            ImportSheet(state: model.importState, dismiss: model.dismissImport)
        }
        .sheet(isPresented: $showLogin) { LoginSheet(sync: sync, backend: model.backend) }
        .confirmationDialog(
            "Your collection and AnkiWeb differ", isPresented: Binding(
                get: { sync.fullSyncChoice != nil }, set: { if !$0 { sync.cancelFullSync() } }),
            titleVisibility: .visible
        ) {
            if sync.fullSyncChoice?.canUpload == true {
                Button("Upload to AnkiWeb (replaces AnkiWeb)", role: .destructive) { resolve(upload: true) }
            }
            if sync.fullSyncChoice?.canDownload == true {
                Button("Download from AnkiWeb (replaces this device)", role: .destructive) { resolve(upload: false) }
            }
            Button("Cancel", role: .cancel) { sync.cancelFullSync() }
        } message: {
            Text("One side has to overwrite the other. A backup of this collection is made first.")
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
                Button("Import deck") { pickingFile = true }.frame(minHeight: Theme.minTarget)
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
            .refreshable { await runSync() }
        }
    }

    private var header: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.headline).foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Circle().fill(sync.hasFailed ? Theme.again : sync.isSignedIn ? Theme.synced : Theme.muted).frame(width: 8, height: 8).accessibilityHidden(true)
                    Text(sync.statusText).font(.footnote)
                        .foregroundStyle(sync.hasFailed ? Theme.again : Theme.muted)
                        .accessibilityIdentifier("sync-status")
                }
            }
            if !typeSize.isAccessibilitySize { Spacer() }
            HStack(spacing: 8) {
                roundButton("arrow.triangle.2.circlepath", "Sync") { Task { await runSync() } }
                roundButton("square.and.arrow.down", "Import deck") { pickingFile = true }
                roundButton("plus", "Add") { addingCard = true }
            }
        }
    }

    private func runSync() async {
        guard sync.isSignedIn else {
            showLogin = true
            return
        }
        guard let backend = model.backend else { return }
        await sync.sync(backend: backend)
    }

    private func resolve(upload: Bool) {
        guard let backend = model.backend else { return }
        Task { await sync.resolveFullSync(upload: upload, backend: backend) }
    }

    private func roundButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundStyle(Theme.text)
                .frame(width: Theme.minTarget, height: Theme.minTarget)
                .background(Theme.control, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(label)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(model.dueTotal)")
                .font(.display(DisplaySize.dueCount))
                .foregroundStyle(Theme.text)
                .minimumScaleFactor(0.5)
                .accessibilityIdentifier("due-total")
            Text("cards due").font(.display(20, relativeTo: .title3)).foregroundStyle(Theme.text2)
            Text(heroLine).font(.footnote).foregroundStyle(Theme.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var heroLine: String {
        "≈ \(model.estimatedMinutes) min · \(model.doneToday) done today · streak —"
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
