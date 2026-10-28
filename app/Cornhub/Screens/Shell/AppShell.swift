import SwiftUI
import Observation

/// Shared navigation state: the selected tab, the deck Browse is scoped to, and whether the tab bar is hidden.
@MainActor @Observable
final class AppState {
    var selection: AppTab = .decks
    /// Deck id Browse should scope to; Browse consumes it and keeps its own scope afterwards.
    var browseDeckID: Int64?
    var visibility = TabBarVisibility(voiceOverRunning: UIAccessibility.isVoiceOverRunning)
    /// Browse selection mode and toasts hide the bar.
    var hideTabBar: Bool {
        get { visibility.selectionMode }
        set { visibility.selectionMode = newValue }
    }
    /// The deck name Browse was last scoped to, kept while the app runs.
    var lastBrowseDeck: String?

    func openBrowse(deckID: Int64) {
        browseDeckID = deckID
        selection = .browse
    }
}

/// Root of the app: the selected tab's screen with the floating tab bar above it.
struct AppShell: View {
    let launch: LaunchOptions
    @State private var appState = AppState()
    @State private var deckModel: DeckHomeModel
    @State private var sync: SyncModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(launch: LaunchOptions) {
        self.launch = launch
        _sync = State(initialValue: SyncModel(stubLogin: launch.stubLogin))
        _deckModel = State(initialValue: DeckHomeModel(launch: launch))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()
            screen
            LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg], startPoint: .top, endPoint: .bottom)
                .frame(height: Theme.tabBarHeight + Theme.tabBarBottomInset + 24)
                .ignoresSafeArea(edges: .bottom)
                .opacity(tabBarHidden ? 0 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .animation(.easeInOut(duration: 0.25), value: tabBarHidden)
            FloatingTabBar(selection: $appState.selection)
                .offset(y: tabBarHidden && !reduceMotion ? Theme.tabBarHeight + Theme.tabBarBottomInset + 40 : 0)
                .opacity(tabBarHidden ? 0 : 1)
                .allowsHitTesting(!tabBarHidden)
                .accessibilityHidden(tabBarHidden)
                .animation(.spring(duration: 0.3), value: tabBarHidden)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in appState.visibility.keyboardUp = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in appState.visibility.keyboardUp = false }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            appState.visibility.voiceOverRunning = UIAccessibility.isVoiceOverRunning
            if UIAccessibility.isVoiceOverRunning { appState.visibility.reset() }
        }
        .onChange(of: appState.selection) { appState.visibility.reset() }
        .tint(Theme.accent)
        .environment(appState)
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

    /// Hidden by Browse selection mode, the software keyboard or scrolling down (see `TabBarVisibility`).
    private var tabBarHidden: Bool { appState.visibility.hidden }

    @ViewBuilder private var screen: some View {
        switch appState.selection {
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
