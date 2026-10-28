import XCTest

/// "Use Cornhub layout" on the invented HSK+-shaped fixture note type (invented content, generated picture).
final class NotetypeLayoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["--seed-imported", "--reset-collection"]
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<12 where !element.isHittable { app.swipeUp() }
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    func testApplyLayoutThenReviewQuestionAndAnswer() {
        app.launch()
        element("tab-settings").tap()
        let manage = element("settings-manage")
        scrollTo(manage)
        manage.tap()
        element("manage-notetypes").tap()
        app.staticTexts["Shared deck style"].firstMatch.tap()
        let entry = element("notetype-layout")
        scrollTo(entry)
        XCTAssertTrue(entry.exists, "Use Cornhub layout is offered for a note type with a hanzi field")
        entry.tap()
        XCTAssertTrue(element("layout-apply").waitForExistence(timeout: 10), "mapping sheet shows")
        sleep(2)
        shot("layout-01-mapping-and-preview")
        let apply = element("layout-apply")
        scrollTo(apply)
        apply.tap()
        XCTAssertTrue(element("layout-undo").waitForExistence(timeout: 10), "applied: Undo is offered")
        shot("layout-02-applied")
        element("layout-done").tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        element("tab-decks").tap()
        app.buttons["Start review"].firstMatch.tap()
        let card = element("review-card")
        XCTAssertTrue(card.waitForExistence(timeout: 15), "review card shows")
        sleep(3)
        shot("layout-03-question")
        card.tap()
        sleep(3)
        shot("layout-04-answer")
    }

    func testRestoreOriginalLayoutIsOfferedAfterApplying() {
        app.launch()
        element("tab-settings").tap()
        let manage = element("settings-manage")
        scrollTo(manage)
        manage.tap()
        element("manage-notetypes").tap()
        app.staticTexts["Shared deck style"].firstMatch.tap()
        let entry = element("notetype-layout")
        scrollTo(entry)
        entry.tap()
        element("layout-apply").tap()
        XCTAssertTrue(element("layout-undo").waitForExistence(timeout: 10))
        element("layout-undo").tap()
        XCTAssertTrue(element("layout-apply").waitForExistence(timeout: 5), "undo goes back to the unconverted state")
        element("layout-apply").tap()
        XCTAssertTrue(element("layout-undo").waitForExistence(timeout: 10))
        element("layout-done").tap()
        entry.tap()
        XCTAssertTrue(element("layout-restore").waitForExistence(timeout: 10), "Restore original layout is offered")
        shot("layout-05-restore")
    }
}
