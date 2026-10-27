import SwiftUI

@main
struct CornhubApp: App {
    var body: some Scene {
        WindowGroup {
            DeckTreeScreen(model: DeckTreeModel(launch: LaunchOptions(arguments: CommandLine.arguments)))
        }
    }
}
