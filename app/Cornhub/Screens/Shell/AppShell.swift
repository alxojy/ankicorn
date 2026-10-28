import SwiftUI

/// Root of the app: the selected tab's screen with the floating tab bar above it.
struct AppShell: View {
    let launch: LaunchOptions
    @State private var selection: AppTab = .decks
    @State private var deckModel: DeckHomeModel
    @State private var sync: SyncModel

    init(launch: LaunchOptions) {
        self.launch = launch
        _sync = State(initialValue: SyncModel(stubLogin: launch.stubLogin))
        _deckModel = State(initialValue: DeckHomeModel(launch: launch))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()
            screen
                .safeAreaPadding(.bottom, Theme.tabBarHeight + Theme.tabBarBottomInset + 8)
            FloatingTabBar(selection: $selection)
        }
        .tint(Theme.accent)
        .task {
            sync.didFinish = { await deckModel.refresh() }
            if launch.showFullSyncChoice {
                sync.fullSyncChoice = FullSyncChoice(
                    canUpload: true, canDownload: true, serverUsn: 0, auth: Anki_Sync_SyncAuth())
            }
            await deckModel.load()
            if let backend = deckModel.backend {
                await sync.backupIfDue(backend)
                if sync.syncOnOpen { await sync.sync(backend: backend) }
            }
        }
        .sheet(isPresented: Binding(get: { deckModel.importState != .idle }, set: { if !$0 { deckModel.dismissImport() } })) {
            ImportSheet(state: deckModel.importState, dismiss: deckModel.dismissImport)
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
            SettingsScreen(sync: sync, backend: deckModel.backend) { url in Task { await deckModel.importPackage(url) } }
        }
    }
}

#Preview {
    AppShell(launch: LaunchOptions(seedSample: true, resetCollection: true))
}
