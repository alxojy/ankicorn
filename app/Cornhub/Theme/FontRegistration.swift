import CoreText
import Foundation

enum FontRegistration {
    /// Registers the bundled Space Grotesk (SIL OFL) so `Font.custom` can find it.
    static func registerBundledFonts() {
        guard let url = Bundle.main.url(forResource: "SpaceGrotesk", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
