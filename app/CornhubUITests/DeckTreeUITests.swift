import XCTest

final class DeckTreeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(largeText: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--seed-sample", "--reset-collection"]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Rows carry the full "Parent::Child" name as their VoiceOver label; the visible text is the last component.
    private func deckRow(_ app: XCUIApplication, _ fullName: String) -> XCUIElement {
        app.otherElements.matching(identifier: "deck-row").matching(NSPredicate(format: "label == %@", fullName)).firstMatch
    }

    private func assertSampleDecksVisible(_ app: XCUIApplication) {
        for name in ["HSK 1", "HSK 2", "HSK 2::Verbs"] {
            XCTAssertTrue(deckRow(app, name).waitForExistence(timeout: 20), "\(name) should be listed")
        }
    }

    func testDeckTreeShowsSeededDecks() {
        let app = launch(largeText: false)
        assertSampleDecksVisible(app)
        XCTAssertTrue(app.staticTexts["Verbs"].exists, "nested deck shows its own name")
        XCTAssertTrue(app.navigationBars["Decks"].exists)
        attachScreenshot(app, named: "deck-tree-default")
    }

    func testDeckTreeAtLargestAccessibilityTextSize() {
        let app = launch(largeText: true)
        assertSampleDecksVisible(app)
        attachScreenshot(app, named: "deck-tree-accessibility-xxxl")
    }
}
