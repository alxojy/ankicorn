import SwiftUI

/// Root of the app: the selected tab's screen with the floating tab bar above it.
struct AppShell: View {
    let launch: LaunchOptions
    @State private var selection: AppTab = .decks
    @State private var deckModel: DeckHomeModel
    @State private var sync = SyncModel()

    init(launch: LaunchOptions) {
        self.launch = launch
        _deckModel = State(initialValue: DeckHomeModel(launch: launch))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()
            screen
                .safeAreaPadding(.bottom, 88)
            FloatingTabBar(selection: $selection)
        }
        .tint(Theme.accent)
        .task {
            sync.reopenCollection = { try await deckModel.reopen() }
            sync.didFinish = { await deckModel.refresh() }
            await deckModel.load()
            if let backend = deckModel.backend {
                await sync.backupIfDue(backend)
                if sync.syncOnOpen { await sync.sync(backend: backend) }
            }
        }
        .onOpenURL { url in Task { await deckModel.importPackage(url) } }
    }

    @ViewBuilder private var screen: some View {
        switch selection {
        case .decks:
            DeckHomeScreen(model: deckModel, sync: sync)
        case .browse:
            BrowseScreen(backend: deckModel.backend)
        case .stats:
            StatsScreen(backend: deckModel.backend)
        case .settings:
            SettingsScreen(sync: sync, backend: deckModel.backend)
        }
    }
}

#Preview {
    AppShell(launch: LaunchOptions(seedSample: true, resetCollection: true))
}
