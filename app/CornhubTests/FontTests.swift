import UIKit
import XCTest

@testable import Cornhub

final class FontTests: XCTestCase {
    func testDisplayFontResolvesToSpaceGrotesk() {
        FontRegistration.registerBundledFonts()
        let font = UIFont(name: FontRegistration.displayFontName, size: 20)
        XCTAssertNotNil(font, "Space Grotesk SemiBold must resolve, not fall back to the system font")
        XCTAssertEqual(font?.fontName, "SpaceGrotesk-SemiBold")
    }
}
