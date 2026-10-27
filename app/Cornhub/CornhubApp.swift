import SwiftUI
import UIKit

@main
struct CornhubApp: App {
    init() {
        FontRegistration.registerBundledFonts()
        Self.styleNavigationTitles()
    }

    /// Screen titles use the display face, scaled with Dynamic Type.
    private static func styleNavigationTitles() {
        guard let base = UIFont(name: FontRegistration.displayFontName, size: 34),
            let inline = UIFont(name: FontRegistration.displayFontName, size: 17)
        else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: base)]
        appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            AppShell(launch: LaunchOptions(arguments: CommandLine.arguments))
                .preferredColorScheme(.dark)
        }
    }
}
