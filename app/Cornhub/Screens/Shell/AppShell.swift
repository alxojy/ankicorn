import SwiftUI

/// Root of the app: the selected tab's screen with the floating tab bar above it.
struct AppShell: View {
    let launch: LaunchOptions
    @State private var selection: AppTab = .decks
    @State private var deckModel: DeckHomeModel

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
        .onOpenURL { url in Task { await deckModel.importPackage(url) } }
    }

    @ViewBuilder private var screen: some View {
        switch selection {
        case .decks:
            DeckHomeScreen(model: deckModel)
        case .browse:
            PlaceholderScreen(title: "Browse", symbol: "magnifyingglass", message: "Search and edit your cards. Coming soon.")
        case .stats:
            PlaceholderScreen(title: "Stats", symbol: "chart.bar", message: "Your reviews and retention will show up here.")
        case .settings:
            PlaceholderScreen(title: "Settings", symbol: "gearshape", message: "Sync and preferences. Coming soon.")
        }
    }
}

#Preview {
    AppShell(launch: LaunchOptions(seedSample: true, resetCollection: true))
}
