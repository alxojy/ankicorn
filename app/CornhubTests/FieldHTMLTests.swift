import XCTest

@testable import Cornhub

final class FieldHTMLTests: XCTestCase {
    private func roundTrip(_ html: String) -> String? {
        FieldHTML.attributed(from: html).map { FieldHTML.html(from: $0) }
    }

    func testPlainText() {
        XCTAssertEqual(roundTrip("明天见"), "明天见")
        XCTAssertEqual(roundTrip(""), "")
    }

    func testBoldItalicUnderlineRoundTrip() throws {
        XCTAssertEqual(roundTrip("<b>明天</b>见"), "<b>明天</b>见")
        XCTAssertEqual(roundTrip("a <i>b</i> <u>c</u>"), "a <i>b</i> <u>c</u>")
        let text = try XCTUnwrap(FieldHTML.attributed(from: "<b>明天</b>见"))
        XCTAssertEqual(String(text.characters), "明天见")
        XCTAssertEqual(text.runs.first?.inlinePresentationIntent, .stronglyEmphasized)
    }

    func testStrongAndEmAreNormalised() {
        XCTAssertEqual(roundTrip("<strong>x</strong><em>y</em>"), "<b>x</b><i>y</i>")
    }

    func testNested() {
        XCTAssertEqual(roundTrip("<b>a<i>b</i></b>"), "<b>a</b><b><i>b</i></b>")
        let text = FieldHTML.attributed(from: "<b>a<i>b</i></b>")
        XCTAssertEqual(text?.runs.count, 2)
    }

    func testBreaksAndEntities() throws {
        let text = try XCTUnwrap(FieldHTML.attributed(from: "a<br>b &amp; c &lt;d&gt; &quot;e&quot;&nbsp;f"))
        XCTAssertEqual(String(text.characters), "a\nb & c <d> \"e\"\u{00A0}f")
        XCTAssertEqual(FieldHTML.html(from: text), "a<br>b &amp; c &lt;d&gt; \"e\"&nbsp;f")
    }

    func testClozeAndSoundStayText() {
        XCTAssertEqual(roundTrip("{{c1::明天}}见 [sound:a.mp3]"), "{{c1::明天}}见 [sound:a.mp3]")
    }

    func testUnsupportedMarkupIsNotConverted() {
        for html in ["<img src=\"a.jpg\">", "<span style=\"color:red\">x</span>", "<div>x</div>", "x &copy; y", "<b>open", "a\nb"] {
            XCTAssertNil(FieldHTML.attributed(from: html), html)
        }
    }
}
