import SwiftUI

@main
struct CornhubApp: App {
    init() { FontRegistration.registerBundledFonts() }

    var body: some Scene {
        WindowGroup {
            AppShell(launch: LaunchOptions(arguments: CommandLine.arguments))
                .preferredColorScheme(.dark)
        }
    }
}
