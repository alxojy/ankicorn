import SwiftUI
import XCTest

@testable import Cornhub

final class AnkiWebInkTests: XCTestCase {
    private var css: String { AnkiWebView.inkCSS }
    private var accent: String { CardWebView.hex(Theme.accent) }

    func testPrimaryButtonUsesAccent() {
        XCTAssertTrue(css.contains(".btn-primary"))
        XCTAssertTrue(css.contains("--bs-btn-bg: \(accent)"))
        XCTAssertTrue(css.contains("--bs-btn-color: \(CardWebView.hex(Theme.onAccent))"))
    }

    func testFormCheckAndSwitchUseAccent() {
        XCTAssertTrue(css.contains(".form-check-input:checked { background-color: \(accent)"))
        XCTAssertTrue(css.contains(".form-switch .form-check-input:checked"))
        XCTAssertTrue(css.contains("accent-color: \(accent)"))
    }

    func testTabsSelectsAndHeadings() {
        XCTAssertTrue(css.contains("[role=tab][aria-selected=true] { color: \(accent)"))
        XCTAssertTrue(css.contains("select, .form-select"))
        XCTAssertTrue(css.contains("\"Space Grotesk\""))
    }

    func testNoBootstrapBlueInOverride() {
        XCTAssertFalse(css.lowercased().contains("#0d6efd"))
    }

    func testFontRouteServesBundledFont() {
        XCTAssertEqual(AnkiWebSchemeHandler.font(named: "SpaceGrotesk-SemiBold.ttf").status, 200)
        XCTAssertEqual(AnkiWebSchemeHandler.font(named: "../x.ttf").status, 404)
    }
}
