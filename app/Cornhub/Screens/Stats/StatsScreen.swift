import SwiftUI

/// Stats tab: Anki's own graphs page for the current deck.
struct StatsScreen: View {
    let backend: Backend?
    @State private var events = AnkiWebEvents()

    var body: some View {
        NavigationStack {
            Group {
                if let backend {
                    AnkiWebContent(page: .graphs, backend: backend, events: events)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Theme.bg)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { events.openLink = { UIApplication.shared.open($0) } }
    }
}
