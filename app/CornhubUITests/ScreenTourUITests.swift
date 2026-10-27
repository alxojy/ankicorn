import XCTest

/// Walks every tab and the main flows on the seeded sample collection, attaching a screenshot per state.
/// Checks are soft (continueAfterFailure) so one broken screen does not hide the rest.
final class ScreenTourUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["--seed-sample", "--reset-collection"]
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tab(_ title: String) {
        let button = app.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "tab \(title) exists")
        button.tap()
    }

    /// Closes the open sheet with its own button (web sheets: Done, native sheets: Cancel or Done).
    private func dismissSheet(file: StaticString = #filePath, line: UInt = #line) {
        for button in [app.buttons["web-done"], app.buttons["Done"], app.buttons["Cancel"]] where button.exists {
            button.tap()
            return
        }
        XCTFail("no Done or Cancel button to close the sheet", file: file, line: line)
    }

    /// Scrolls a lazy list until the element is on screen.
    private func scrollTo(_ element: XCUIElement) {
        var tries = 0
        let tabTop = app.descendants(matching: .any)["tab-settings"].frame.minY
        while !element.exists || !element.isHittable || element.frame.maxY > tabTop, tries < 8 {
            app.collectionViews.firstMatch.swipeUp(velocity: .fast)
            tries += 1
        }
    }

    func testHomeAndDeckOverview() {
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["due-total"].waitForExistence(timeout: 30), "due hero shows")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'done today'")).firstMatch
                .waitForExistence(timeout: 10), "hero line reads 'N done today'")
        shot("01-home")
        app.swipeUp()
        shot("02-home-scrolled")
        app.swipeDown()
        let tile = app.descendants(matching: .any).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "deck tiles show")
        let tileLabel = tile.label
        XCTAssertTrue(tileLabel.hasPrefix("HSK 1"), "first tile is HSK 1, got \(tileLabel)")
        // The home tile and the overview use the same engine counts: the 45 cards are capped by the daily new limit.
        XCTAssertTrue(tileLabel.contains("20 new"), "home tile shows 20 new, got \(tileLabel)")
        tile.tap()
        sleep(2)
        shot("03-deck-overview")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "New: 20")).firstMatch.waitForExistence(timeout: 5), "overview shows 20 new (daily limit of the 45 cards)")
        XCTAssertTrue(app.staticTexts["45 cards"].exists, "overview shows 45 cards")
        let options = app.descendants(matching: .any)["deck-options-button"]
        if options.waitForExistence(timeout: 5) {
            options.tap()
            XCTAssertTrue(
                app.webViews.staticTexts["Daily Limits"].waitForExistence(timeout: 40),
                "deck options page has loaded")
            sleep(1)
            shot("04-deck-options-web")
            dismissSheet()
        }
        let custom = app.descendants(matching: .any)["custom-study-button"]
        if custom.waitForExistence(timeout: 5) {
            custom.tap()
            sleep(1)
            shot("05-custom-study")
            dismissSheet()
        }
    }

    func testReviewFlow() {
        app.launch()
        let start = app.buttons["Start review"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Start review exists")
        start.tap()
        let card = app.descendants(matching: .any)["review-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "review card shows")
        sleep(2)
        shot("10-review-question")
        card.tap()
        sleep(2)
        shot("11-review-answer")
        let good = app.descendants(matching: .any)["grade-good"]
        XCTAssertTrue(good.waitForExistence(timeout: 5), "Good button shows")
        good.tap()
        sleep(2)
        shot("12-review-next-card")
        card.swipeRight()
        sleep(2)
        shot("13-review-after-swipe")
        let more = app.buttons["More"].firstMatch
        if more.waitForExistence(timeout: 5) {
            more.tap()
            sleep(1)
            shot("14-review-more-menu")
            if app.buttons["Card info"].exists {
                app.buttons["Card info"].tap()
                sleep(4)
                shot("15-card-info-web")
                dismissSheet()
            } else {
                app.tap()
            }
        }
        let undo = app.descendants(matching: .any)["review-undo"]
        if undo.exists { undo.tap(); sleep(1); shot("16-review-after-undo") }
        let close = app.descendants(matching: .any)["review-close"]
        XCTAssertTrue(close.exists, "close button exists")
        close.tap()
        sleep(1)
        shot("17-home-after-review")
    }

    func testAddCard() {
        app.launch()
        let add = app.buttons["Add"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 30), "Add button exists")
        add.tap()
        sleep(2)
        shot("20-add-card")
        let field = app.descendants(matching: .any)["editor-field-0"]
        if field.waitForExistence(timeout: 5) {
            field.tap()
            field.typeText("学")
            app.buttons["Bold"].firstMatch.tap()
            field.typeText("粗")
            shot("21-add-card-typing")
            let shown = (field.value as? String) ?? ""
            XCTAssertFalse(shown.contains("<b>"), "bold shows as styling, not a literal tag: \(shown)")
            XCTAssertTrue(shown.contains("粗"), "typed text is in the field")
        }
        let chip = app.descendants(matching: .any)["editor-notetype-chip"]
        XCTAssertTrue(chip.exists, "notetype chip exists")
        chip.tap()
        sleep(1)
        shot("22-notetype-picker")
        let basic = app.buttons["Basic"].firstMatch
        XCTAssertTrue(basic.waitForExistence(timeout: 5), "picker lists Basic")
        basic.tap()
        sleep(1)
        shot("23-notetype-basic")
        XCTAssertTrue(app.descendants(matching: .any)["editor-field-1"].waitForExistence(timeout: 5), "Basic has a Back field")
    }

    func testBrowse() {
        app.launch()
        tab("Browse")
        sleep(3)
        shot("30-browse")
        let filter = app.descendants(matching: .any)["browse-filter"]
        if filter.waitForExistence(timeout: 5) { filter.tap(); sleep(1); shot("31-browse-filter"); dismissSheet() }
        let row = app.buttons.matching(identifier: "browse-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "browse lists rows")
        row.tap()
        sleep(2)
        shot("32-browse-edit-note")
        XCTAssertTrue(app.descendants(matching: .any)["editor-field-0"].waitForExistence(timeout: 5), "row opens the note editor")
    }

    func testStats() {
        app.launch()
        tab("Stats")
        sleep(4)
        shot("40-stats")
        app.swipeUp()
        shot("41-stats-scrolled")
        let more = app.descendants(matching: .any)["more-stats"]
        if more.waitForExistence(timeout: 5) { more.tap(); sleep(5); shot("42-more-stats-web") }
    }

    func testSettings() {
        app.launch()
        tab("Settings")
        sleep(2)
        shot("50-settings")
        app.swipeUp()
        shot("51-settings-scrolled")
        for _ in 0..<6 { app.collectionViews.firstMatch.swipeUp(velocity: .fast) }
        shot("51b-settings-bottom")
        let tabTop = app.descendants(matching: .any)["tab-settings"].frame.minY
        XCTAssertLessThanOrEqual(
            app.descendants(matching: .any)["settings-tools"].frame.maxY, tabTop, "last Settings row clears the tab bar")
        for (id, name) in [("settings-manage", "52-manage"), ("settings-tools", "53-tools"),
                           ("settings-import-export", "54-import-export")] {
            let item = app.descendants(matching: .any)[id]
            scrollTo(item)
            guard item.exists else { XCTFail("\(id) not found"); continue }
            item.tap()
            sleep(2)
            shot(name)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "back on Settings after \(id)")
        }
        for _ in 0..<6 { app.collectionViews.firstMatch.swipeDown(velocity: .fast) }
        let login = app.descendants(matching: .any)["settings-login"]
        scrollTo(login)
        XCTAssertTrue(login.exists, "login row exists")
        login.tap()
        sleep(1)
        shot("55-login")
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5) || app.secureTextFields.firstMatch.exists, "login sheet shows fields")
    }

    func testLargestTextSize() {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        sleep(4)
        shot("60-home-xxxl")
        app.buttons["Start review"].firstMatch.tap()
        sleep(3)
        shot("61-review-xxxl")
    }
}
