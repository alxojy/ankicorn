import XCTest

@testable import Cornhub

final class CardStyleTests: XCTestCase {
    func testLightBackgroundWithoutColourGetsDarkText() {
        let style = CardStyle.decide(css: ImportedFixtures.lightCSS)
        XCTAssertEqual(style, .light(background: "#FDF6E3"))
        XCTAssertTrue(CardWebView.baseCSS(style).contains("color: #222222"))
        let text = CardStyle.rgb(of: "#222222")!, box = CardStyle.rgb(of: "#fdf6e3")!
        XCTAssertGreaterThanOrEqual(CardStyle.contrast(text, box), 3, "default text reads on the deck's own background")
    }

    func testDarkBackgroundKeepsLightInkText() {
        let style = CardStyle.decide(css: ImportedFixtures.darkCSS)
        XCTAssertEqual(style, .dark(background: "#1B2A3A"))
        XCTAssertTrue(CardWebView.baseCSS(style).contains("color: \(CardWebView.hex(Theme.text))"))
        let text = CardStyle.rgb(of: CardWebView.hex(Theme.text))!, box = CardStyle.rgb(of: "#1b2a3a")!
        XCTAssertGreaterThanOrEqual(CardStyle.contrast(text, box), 3)
    }

    func testUnsetOrNonOpaqueBackgroundKeepsInk() {
        XCTAssertEqual(CardStyle.decide(css: ".card { color: red; }"), .ink)
        XCTAssertEqual(CardStyle.decide(css: ""), .ink)
        XCTAssertEqual(CardStyle.decide(css: ".card { background: transparent }"), .ink)
        XCTAssertEqual(CardStyle.decide(css: ".card { background: rgba(255,255,255,0.5) }"), .ink)
        XCTAssertEqual(CardStyle.decide(css: ".nightMode .card { background: white }"), .ink)
        XCTAssertEqual(CardStyle.decide(css: ".card { background: linear-gradient(red, blue) }"), .ink)
    }

    func testStockBasicIsLightAndColourParsing() {
        XCTAssertEqual(CardStyle.decide(css: ".card { color: black; background-color: white; }"), .light(background: "#FFFFFF"))
        XCTAssertEqual(CardStyle.rgb(of: "#fff"), CardStyle.RGB(red: 255, green: 255, blue: 255))
        XCTAssertEqual(CardStyle.rgb(of: "rgb(10, 20, 30)"), CardStyle.RGB(red: 10, green: 20, blue: 30))
        XCTAssertEqual(CardStyle.decide(css: ".card{background:#000 url(x.png)}"), .dark(background: "#000000"))
    }

    func testDocumentSetsNightClassesFontAliasesAndPlaceholderScript() {
        let html = CardWebView.document(body: "x", css: "")
        XCTAssertTrue(html.contains("class=\"nightMode night_mode\""))
        XCTAssertTrue(html.contains("font-family: \"Kaiti\"") && html.contains("PingFangSC-Regular"))
        XCTAssertTrue(html.contains("Image missing"))
    }
}
