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
        XCTAssertTrue(app.buttons["Sync"].exists && app.buttons["Add card"].exists, "header has Sync and Add card")
        XCTAssertFalse(app.buttons["Import deck"].exists, "Import deck left the header")
        let due = app.descendants(matching: .any)["due-total"].firstMatch
        let caption = app.staticTexts["cards due"].firstMatch
        XCTAssertTrue(caption.exists, "cards due shows")
        // Baseline-aligned: the small caption sits in the lower part of the big count's frame, not above or below it.
        XCTAssertGreaterThan(caption.frame.midY, due.frame.midY, "cards due sits on the count's baseline, below its middle")
        XCTAssertLessThanOrEqual(caption.frame.maxY, due.frame.maxY + 4, "cards due does not drop below the count's row")
        XCTAssertGreaterThan(caption.frame.minX, due.frame.minX + 60, "cards due is to the right of the count")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'streak'")).firstMatch.exists,
            "hero line shows the streak")
        XCTAssertTrue(
            app.descendants(matching: .any).matching(NSPredicate(format: "label MATCHES %@", "\\d+ new, \\d+ learning, \\d+ review"))
                .firstMatch.exists, "due bar legend is always present")
        XCTAssertGreaterThanOrEqual(app.buttons["start-review"].firstMatch.frame.height, 60, "Start review is 60 pt")
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
        let summary = app.descendants(matching: .any)["deck-summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5), "overview shows the summary line")
        XCTAssertTrue(summary.label.contains("20 new"), "overview shows 20 new (daily limit of the 45 cards), got \(summary.label)")
        XCTAssertTrue(summary.label.contains("45 cards"), "overview shows 45 cards, got \(summary.label)")
        let options = deckMenuItem("deck-options-button")
        if options.waitForExistence(timeout: 5) {
            options.tap()
            XCTAssertTrue(
                app.webViews.staticTexts["Daily Limits"].waitForExistence(timeout: 40),
                "deck options page has loaded")
            sleep(1)
            shot("04-deck-options-web")
            dismissSheet()
        }
        let custom = deckMenuItem("custom-study-button")
        if custom.waitForExistence(timeout: 5) {
            custom.tap()
            sleep(1)
            shot("05-custom-study")
            dismissSheet()
        }
    }

    /// The tab bar slides away while scrolling down a deck overview and the last row clears it at the end.
    func testTabBarMinimizesOnScroll() {
        app.launchArguments += ["--seed-many-subdecks"]
        app.launch()
        let tile = app.descendants(matching: .any).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "deck tiles show")
        let parent = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'HSK 2'")).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(parent.exists, "the HSK 2 tile shows")
        parent.tap()
        let tabBar = app.descendants(matching: .any)["tab-settings"]
        let study = app.buttons["study-button"]
        XCTAssertTrue(study.waitForExistence(timeout: 10), "overview shows")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "subdeck-row").count > 6, "subdeck rows show")
        XCTAssertTrue(tabBar.isHittable, "tab bar shows before scrolling")
        shot("tabbar-01-before")
        app.swipeUp()
        sleep(1)
        XCTAssertFalse(tabBar.isHittable, "tab bar is not hittable while scrolled down")
        shot("tabbar-02-minimized")
        app.swipeDown()
        sleep(1)
        XCTAssertTrue(tabBar.isHittable, "tab bar is hittable again after scrolling up")
        for _ in 0..<4 { app.swipeUp(velocity: .fast) }
        sleep(1)
        XCTAssertTrue(tabBar.isHittable, "tab bar is back at the end of the content")
        let lastRow = app.descendants(matching: .any).matching(identifier: "subdeck-row").allElementsBoundByIndex.last
        let last = lastRow?.exists == true ? lastRow! : study
        XCTAssertLessThanOrEqual(last.frame.maxY, tabBar.frame.minY, "the last row sits above the tab bar")
        shot("tabbar-03-end")
    }

    /// Cards of invented shared-deck note types: a light deck background with no text colour, and a dark one.
    private func reviewImportedCards(arguments: [String], prefix: String, imageMissing: Bool) {
        app.launchArguments = ["--seed-imported", "--reset-collection"] + arguments
        app.launch()
        let start = app.buttons["Start review"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Start review exists")
        start.tap()
        let card = app.descendants(matching: .any)["review-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "review card shows")
        sleep(3)
        shot("\(prefix)-light-question")
        card.tap()
        sleep(3)
        shot("\(prefix)-light-answer")
        XCTAssertFalse(app.staticTexts["Image missing"].exists, "no placeholder text for a missing image")
        if imageMissing { XCTAssertEqual(app.images.matching(identifier: "fixture-image").count, 0) }
        let replay = app.buttons["review-replay"]
        let web = app.webViews.firstMatch
        if replay.exists, web.exists {
            XCTAssertFalse(replay.frame.intersects(web.frame), "replay sits outside the card HTML")
        }
        let good = app.descendants(matching: .any)["grade-good"]
        XCTAssertTrue(good.waitForExistence(timeout: 5), "Good button shows")
        good.tap()
        sleep(3)
        shot("\(prefix)-dark-question")
        card.tap()
        sleep(3)
        shot("\(prefix)-dark-answer")
    }

    func testImportedDeckCardsAreReadableWithMedia() {
        reviewImportedCards(arguments: [], prefix: "20-imported", imageMissing: false)
    }

    /// Opens the first imported card's answer (sentence plus picture) and checks the picture's size.
    func testCardPictureIsStandardSizeAndOpensFullScreen() {
        app.launchArguments = ["--seed-imported", "--reset-collection"]
        app.launch()
        let start = app.buttons["Start review"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Start review exists")
        start.tap()
        let card = app.descendants(matching: .any)["review-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "review card shows")
        sleep(3)
        card.tap()
        sleep(3)
        let cardFrame = card.frame
        // Light fixture first, then the dark one (its CSS sets img { width: 100%; height: 600px }).
        for round in 0..<2 {
            // The card is one accessibility element, so only an image inside it is the card's picture
            // (images elsewhere on screen, such as grade icons, are not).
            let picture = card.images.firstMatch
            if picture.exists {
                XCTAssertLessThanOrEqual(picture.frame.height, 220.5, "picture is at most the cap (round \(round))")
                XCTAssertLessThanOrEqual(picture.frame.maxY, cardFrame.maxY, "picture bottom is inside the card")
            }
            shot("22-picture-size-\(round)")
            if round == 0 {
                app.descendants(matching: .any)["grade-good"].tap()
                sleep(3)
                card.tap()
                sleep(3)
            }
        }
    }

    func testTappingCardPictureShowsViewerAndCloseKeepsCard() {
        app.launchArguments = ["--seed-imported", "--reset-collection"]
        app.launch()
        app.buttons["Start review"].firstMatch.tap()
        let card = app.descendants(matching: .any)["review-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "review card shows")
        sleep(3)
        card.tap()
        sleep(3)
        // The answer is centred in the card (sentence, then the picture); tap down the middle until the picture is hit.
        let viewer = app.descendants(matching: .any)["image-viewer"]
        for dy in [0.55, 0.62, 0.7, 0.48, 0.78, 0.4] where !viewer.exists {
            card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            _ = viewer.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(viewer.exists, "tapping the picture opens the viewer")
        shot("23-picture-viewer")
        app.buttons["image-viewer-close"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["grade-good"].waitForExistence(timeout: 5), "card is unchanged")
        XCTAssertFalse(viewer.exists, "viewer closed")
    }

    func testImportedDeckCardsShowPlaceholderForMissingImage() {
        reviewImportedCards(arguments: ["--drop-fixture-image"], prefix: "21-imported-no-image", imageMissing: true)
    }

    func testFullSyncChoiceDialog() {
        app.launchArguments += ["--show-full-sync-choice"]
        app.launch()
        let download = app.buttons["Download from AnkiWeb"]
        let upload = app.buttons["Upload to AnkiWeb"]
        XCTAssertTrue(download.waitForExistence(timeout: 30), "Download button shows")
        XCTAssertTrue(upload.exists, "Upload shows")
        XCTAssertTrue(app.staticTexts["Sync conflict"].exists, "title reads Sync conflict")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Download replaces this device'")).firstMatch
                .exists, "message explains what each choice replaces")
        // Short labels with no parenthetical text render at the same system size, so the three rows have equal heights.
        XCTAssertEqual(download.frame.height, upload.frame.height, accuracy: 1)
        shot("full-sync-choice")
        // On iPhone the system shows this as a popover with no Cancel row; tapping outside it is the cancel.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
        XCTAssertTrue(download.waitForNonExistence(timeout: 5), "Tapping outside closes the prompt")
        XCTAssertTrue(app.descendants(matching: .any)["due-total"].exists, "Decks still shows")
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
        XCTAssertTrue(app.buttons["Show answer"].firstMatch.exists, "question side has a Show answer button")
        XCTAssertFalse(app.buttons["grade-good"].exists, "no grade buttons before reveal")
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

    func testUnburyShowsOnlyWithBuriedCards() {
        app.launchArguments = ["--seed-sample", "--seed-buried", "--reset-collection"]
        app.launch()
        let tile = app.descendants(matching: .any).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "deck tiles show")
        tile.tap()
        let unbury = deckMenuItem("unbury-button")
        XCTAssertTrue(unbury.waitForExistence(timeout: 10), "Unbury shows in the menu with buried cards")
        shot("03b-deck-overview-buried")
        unbury.tap()
        XCTAssertTrue(
            app.staticTexts["Unburied 2 cards"].waitForExistence(timeout: 10), "confirmation shows the count")
        app.buttons["deck-actions-menu"].tap()
        XCTAssertTrue(app.buttons["custom-study-button"].waitForExistence(timeout: 5), "menu reopens")
        XCTAssertFalse(app.buttons["unbury-button"].exists, "Unbury disappears afterwards")
        app.buttons["deck-actions-menu"].tap()
        shot("03c-deck-overview-unburied")
    }

    func testNoUnburyWhenNothingBuried() {
        app.launch()
        let tile = app.descendants(matching: .any).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "deck tiles show")
        tile.tap()
        XCTAssertTrue(app.buttons["study-button"].waitForExistence(timeout: 10), "overview shows")
        XCTAssertTrue(deckMenuItem("custom-study-button").waitForExistence(timeout: 5), "menu shows")
        XCTAssertFalse(app.buttons["unbury-button"].exists, "no Unbury without buried cards")
    }

    func testDeckOptionsDoneKeepsEdits() {
        app.launch()
        let tile = app.descendants(matching: .any).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "deck tiles show")
        tile.tap()
        let options = deckMenuItem("deck-options-button")
        XCTAssertTrue(options.waitForExistence(timeout: 10), "Deck options menu item")
        options.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["anki-web-deck-options"].waitForExistence(timeout: 30), "options page opens")
        sleep(3)
        shot("04b-deck-options-header")
        // Edit "New cards/day" in the page, then Done: the app saves or asks Save / Discard / Cancel.
        let field = app.webViews.textFields.firstMatch
        if field.waitForExistence(timeout: 10) {
            field.tap()
            field.typeText("7")
        }
        app.buttons["web-done"].tap()
        // The page's own Save button also reads "Save"; the prompt's one lives in its action sheet.
        let save = app.sheets.buttons["Save"].firstMatch
        if save.waitForExistence(timeout: 5) {
            shot("04c-deck-options-save-prompt")
            save.tap()
        }
        XCTAssertTrue(options.waitForExistence(timeout: 15), "the sheet closes after Done / Save")
        options.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["anki-web-deck-options"].waitForExistence(timeout: 30), "options reopen")
        let again = app.webViews.textFields.firstMatch
        XCTAssertTrue(again.waitForExistence(timeout: 15), "the options field shows again")
        XCTAssertTrue(((again.value as? String) ?? "").contains("7"), "the saved edit persisted")
    }

    func testCongratsUndoBringsCardBack() {
        app.launchArguments = ["--seed-one-due", "--reset-collection"]
        app.launch()
        let start = app.buttons["Start review"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Start review exists")
        start.tap()
        let card = app.descendants(matching: .any)["review-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "the one due card shows")
        sleep(2)
        card.tap()
        // Easy graduates the new card, so nothing is left due (Good would put it into learning and show it again).
        let easy = app.descendants(matching: .any)["grade-easy"]
        XCTAssertTrue(easy.waitForExistence(timeout: 5), "Easy button shows")
        easy.tap()
        let congrats = app.descendants(matching: .any)["congrats"]
        XCTAssertTrue(congrats.waitForExistence(timeout: 10), "congrats shows after the last card")
        XCTAssertFalse(app.buttons["More"].exists, "no More menu on congrats")
        XCTAssertTrue(app.buttons["review-close"].exists, "close shows on congrats")
        let undo = app.buttons["review-undo"]
        XCTAssertTrue(undo.exists && undo.isEnabled, "Undo shows and is enabled after grading")
        shot("18-congrats-before-undo")
        undo.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the graded card is back")
        XCTAssertTrue(congrats.waitForNonExistence(timeout: 5), "congrats is gone")
        XCTAssertTrue(app.buttons["Show answer"].firstMatch.exists, "card is on its question side")
        sleep(5)
        shot("19-congrats-after-undo")
    }

    func testCongratsWithNothingGradedHasNoDeadControls() {
        app.launchArguments = ["--seed-no-due", "--reset-collection"]
        app.launch()
        let start = app.buttons["Start review"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Start review exists")
        start.tap()
        XCTAssertTrue(app.descendants(matching: .any)["congrats"].waitForExistence(timeout: 15), "congrats shows")
        XCTAssertTrue(app.buttons["review-close"].exists, "close shows")
        XCTAssertFalse(app.buttons["More"].exists, "no More menu")
        XCTAssertFalse(app.buttons["review-undo"].exists, "no Undo with nothing to undo")
        shot("18b-congrats-nothing-graded")
    }

    func testAddCard() {
        app.launch()
        let add = app.buttons["Add card"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 30), "Add button exists")
        add.tap()
        sleep(2)
        shot("20-add-card")
        // Auto-pinyin only runs on the Chinese note type; pick it if the collection defaults to another.
        let typeChip = app.descendants(matching: .any)["editor-notetype-chip"]
        if typeChip.waitForExistence(timeout: 5), !typeChip.label.contains("Chinese") {
            typeChip.tap()
            let chinese = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Chinese'")).firstMatch
            XCTAssertTrue(chinese.waitForExistence(timeout: 5), "picker lists the Chinese note type")
            chinese.tap()
            sleep(1)
        }
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
            let pinyin = app.descendants(matching: .any)["editor-field-1"]
            if pinyin.exists {
                field.typeText("生")
                let expected = NSPredicate(format: "value CONTAINS 'shēng'")
                XCTAssertEqual(
                    XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: expected, object: pinyin)], timeout: 5),
                    .completed, "Pinyin fills from the Hanzi field")
                shot("21b-add-card-auto-pinyin")
            }
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
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "browse has a search field")
        let tabBar = app.descendants(matching: .any)["tab-settings"].frame
        XCTAssertFalse(search.frame.intersects(tabBar), "search field does not overlap the tab bar")
        XCTAssertLessThan(search.frame.minY, tabBar.minY, "search field sits above the tab bar")
        let rowsBefore = app.buttons.matching(identifier: "browse-row").count
        search.tap()
        search.typeText("zzzqqqnomatch\n")
        sleep(2)
        shot("30b-browse-search")
        XCTAssertLessThan(app.buttons.matching(identifier: "browse-row").count, max(rowsBefore, 1), "query filters results")
        if app.buttons["Clear text"].exists { app.buttons["Clear text"].tap() }
        search.typeText("hello\n")
        sleep(2)
        XCTAssertTrue(app.buttons.matching(identifier: "browse-row").firstMatch.waitForExistence(timeout: 5), "matching query lists rows")
        if app.keyboards.count > 0, app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        let filter = app.descendants(matching: .any)["browse-filter"]
        if filter.waitForExistence(timeout: 5) { filter.tap(); sleep(1); shot("31-browse-filter"); dismissSheet() }
        let row = app.buttons.matching(identifier: "browse-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "browse lists rows")
        row.tap()
        sleep(2)
        shot("32-browse-edit-note")
        XCTAssertTrue(app.descendants(matching: .any)["editor-field-0"].waitForExistence(timeout: 5), "row opens the note editor")
    }

    func testBrowseLiveSearchAndKeyboardHidesTabBar() {
        app.launch()
        tab("Browse")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10), "browse has a search field")
        let full = browseCount()
        XCTAssertGreaterThan(full, 0, "full list shows cards")
        search.tap()
        let settings = app.descendants(matching: .any)["tab-settings"]
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "keyboard is up")
        sleep(1)
        shot("33-browse-keyboard-tabbar")
        XCTAssertTrue(!settings.isHittable || settings.frame.minY >= app.keyboards.firstMatch.frame.minY,
                      "tab bar is hidden or below the keyboard")
        search.typeText("zzzqqqnomatch")
        let filtered = NSPredicate { _, _ in self.browseCount() < full }
        wait(for: [XCTNSPredicateExpectation(predicate: filtered, object: nil)], timeout: 10)
        XCTAssertLessThan(browseCount(), full, "rows filter without pressing return")
        shot("34-browse-live-filtered")
        let clear = app.buttons["Clear text"]
        if clear.waitForExistence(timeout: 3) { clear.tap() }
        let restored = NSPredicate { _, _ in self.browseCount() == full }
        wait(for: [XCTNSPredicateExpectation(predicate: restored, object: nil)], timeout: 10)
        XCTAssertEqual(browseCount(), full, "clearing the field restores the full count")
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else if app.keyboards.buttons["Search"].exists {
            app.keyboards.buttons["Search"].tap()
        }
        let back = NSPredicate { _, _ in settings.isHittable }
        wait(for: [XCTNSPredicateExpectation(predicate: back, object: nil)], timeout: 10)
        XCTAssertTrue(settings.isHittable, "tab bar returns after the keyboard closes")
        shot("35-browse-keyboard-closed")
    }

    private func browseCount() -> Int {
        let element = app.descendants(matching: .any)["browse-count"].firstMatch
        guard element.waitForExistence(timeout: 5) else { return -1 }
        let label = element.label
        return Int(label.split(separator: " ").first ?? "") ?? -1
    }

    func testBrowseDeckScopeAndDelete() {
        app.launch()
        tab("Browse")
        let chip = app.buttons["browse-deck-chip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10), "deck chip exists")
        chip.tap()
        let pick = app.buttons["HSK 2"].firstMatch
        XCTAssertTrue(pick.waitForExistence(timeout: 5), "picker lists HSK 2")
        shot("33-browse-deck-picker")
        pick.tap()
        let count = app.descendants(matching: .any)["browse-count"].firstMatch
        XCTAssertTrue(count.waitForExistence(timeout: 5), "count line shows")
        XCTAssertTrue(count.label.hasSuffix("in HSK 2"), "count line names the deck, got \(count.label)")
        let before = browseCount()
        XCTAssertGreaterThan(before, 2, "HSK 2 has cards")
        app.buttons["browse-select"].tap()
        let rows = app.buttons.matching(identifier: "browse-row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        rows.element(boundBy: 0).tap()
        rows.element(boundBy: 1).tap()
        sleep(1)
        shot("34-browse-select")
        let delete = app.buttons["browse-delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "delete button exists")
        XCTAssertTrue(delete.isHittable, "delete button is hittable")
        let tabBar = app.descendants(matching: .any)["tab-settings"].frame
        XCTAssertFalse(delete.frame.intersects(tabBar), "delete button does not overlap the tab bar")
        delete.tap()
        let confirm = app.buttons["browse-delete-confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "delete asks for confirmation")
        shot("35-browse-delete-confirm")
        confirm.tap()
        let undo = app.buttons["browse-undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "undo toast shows")
        shot("36-browse-undo")
        sleep(1)
        XCTAssertLessThan(browseCount(), before, "count drops after delete")
        undo.tap()
        sleep(2)
        XCTAssertEqual(browseCount(), before, "undo brings the cards back")
    }

    /// Opens the overview's ⋯ menu and returns the item with this identifier.
    private func deckMenuItem(_ id: String) -> XCUIElement {
        let menu = app.buttons["deck-actions-menu"]
        if menu.waitForExistence(timeout: 10) { menu.tap() }
        return app.buttons[id]
    }

    /// A parent deck with 4 subdecks shows Study and every subdeck row without scrolling; the menu lists the actions.
    func testDeckOverviewFitsOnOneScreen() {
        app.launchArguments += ["--seed-four-subdecks"]
        app.launch()
        let parent = deckTile("HSK 2")
        XCTAssertTrue(parent.waitForExistence(timeout: 30), "HSK 2 tile exists")
        parent.tap()
        let study = app.buttons["study-button"]
        XCTAssertTrue(study.waitForExistence(timeout: 10), "overview shows")
        let rows = app.descendants(matching: .any).matching(identifier: "subdeck-row")
        XCTAssertEqual(rows.count, 4, "four subdeck rows")
        XCTAssertTrue(study.isHittable, "Study visible without scrolling")
        for row in rows.allElementsBoundByIndex { XCTAssertTrue(row.isHittable, "row \(row.label) visible without scrolling") }
        XCTAssertFalse(app.buttons["browse-cards-button"].exists, "no full-width Browse button")
        shot("03d-deck-overview-compact")
        app.buttons["deck-actions-menu"].tap()
        for id in ["custom-study-button", "browse-cards-button", "deck-options-button", "deck-action-rename", "deck-action-delete"] {
            XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 5), "menu lists \(id)")
        }
        shot("03e-deck-overview-menu")
    }

    private func deckTile(_ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == 'deck-tile' AND label BEGINSWITH %@", "\(name):")).firstMatch
    }

    func testDeckRenameAndDelete() {
        app.launch()
        let tile = deckTile("HSK 2")
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "HSK 2 tile exists")
        tile.press(forDuration: 1.2)
        let delete = app.buttons["deck-action-delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "long press shows Delete")
        XCTAssertTrue(app.buttons["deck-action-rename"].exists, "menu offers Rename")
        XCTAssertTrue(app.buttons["deck-action-options"].exists, "menu offers Options")
        shot("40-deck-menu")
        delete.tap()
        let confirm = app.buttons["deck-delete-confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "delete asks for confirmation")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'cards and any subdecks will be deleted'")).firstMatch.exists,
            "confirmation states the card count")
        shot("41-deck-delete-confirm")
        confirm.tap()
        let undo = app.buttons["deck-undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "undo toast shows")
        shot("42-deck-undo-toast")
        let tabBar = app.descendants(matching: .any)["tab-settings"]
        XCTAssertFalse(tabBar.exists && tabBar.isHittable && tabBar.frame.intersects(undo.frame), "toast does not overlap the tab bar")
        XCTAssertFalse(deckTile("HSK 2").exists, "tile is gone after delete")
        undo.tap()
        XCTAssertTrue(deckTile("HSK 2").waitForExistence(timeout: 10), "undo brings the tile back")

        deckTile("HSK 2").press(forDuration: 1.2)
        let rename = app.buttons["deck-action-rename"]
        XCTAssertTrue(rename.waitForExistence(timeout: 5), "menu offers Rename again")
        rename.tap()
        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "rename field shows")
        XCTAssertEqual(field.value as? String, "HSK 2", "field is prefilled with the full name")
        shot("43-deck-rename")
        field.tap()
        field.typeText("b")
        app.alerts.buttons["Rename"].firstMatch.tap()
        XCTAssertTrue(deckTile("HSK 2b").waitForExistence(timeout: 10), "tile shows the new name")
        shot("44-deck-renamed")
    }

    func testBrowseFromDeckOverview() {
        app.launch()
        let tile = app.descendants(matching: .any).matching(identifier: "deck-tile").firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 30), "deck tiles show")
        tile.tap()
        let browse = deckMenuItem("browse-cards-button")
        XCTAssertTrue(browse.waitForExistence(timeout: 10), "menu has Browse cards")
        browse.tap()
        let count = app.descendants(matching: .any)["browse-count"].firstMatch
        XCTAssertTrue(count.waitForExistence(timeout: 10), "Browse opens")
        XCTAssertTrue(count.label.hasSuffix("in HSK 1"), "scoped to HSK 1, got \(count.label)")
        shot("37-browse-from-overview")
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
        let importer = app.descendants(matching: .any)["settings-import-export"]
        scrollTo(importer)
        importer.tap()
        XCTAssertTrue(app.buttons["import-deck"].waitForExistence(timeout: 5), "Settings › Import and export has Import deck")
        app.navigationBars.buttons.element(boundBy: 0).tap()
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
        // A stub sign-in from an earlier test can survive in the simulator's keychain: sign out first.
        let logout = app.buttons["Log out"].firstMatch
        if logout.waitForExistence(timeout: 2) {
            logout.tap()
            app.buttons.matching(identifier: "Log out").allElementsBoundByIndex.last?.tap()
            sleep(1)
        }
        let login = app.descendants(matching: .any)["settings-login"]
        scrollTo(login)
        XCTAssertTrue(login.exists, "login row exists")
        XCTAssertFalse(app.staticTexts["Status"].exists, "no Status row while signed out")
        XCTAssertFalse(app.buttons["Sync now"].exists, "no Sync now while signed out")
        login.tap()
        sleep(1)
        shot("55-login")
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5) || app.secureTextFields.firstMatch.exists, "login sheet shows fields")
    }

    func testLoginRefreshesSettings() {
        app.launchArguments += ["--stub-login"]
        app.launch()
        tab("Settings")
        let login = app.descendants(matching: .any)["settings-login"]
        scrollTo(login)
        XCTAssertTrue(login.exists, "signed out: login row")
        shot("56-signed-out")
        login.tap()
        let username = app.textFields["login-username"]
        XCTAssertTrue(username.waitForExistence(timeout: 5))
        username.tap()
        username.typeText("testuser")
        let password = app.secureTextFields["login-password"]
        password.tap()
        password.typeText("secret")
        app.buttons["login-submit"].tap()
        XCTAssertTrue(app.buttons["settings-logout"].waitForExistence(timeout: 5), "Log out appears without leaving Settings")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "testuser")).firstMatch.exists,
            "Signed in as testuser")
        XCTAssertFalse(login.exists, "login row is gone")
        XCTAssertFalse(app.staticTexts["Status"].exists, "no Status row")
        let syncNow = app.buttons["settings-sync-now"]
        scrollTo(syncNow)
        XCTAssertTrue(syncNow.exists, "Sync now after login")
        let mediaToggle = app.switches["Sync media"]
        XCTAssertTrue(mediaToggle.exists, "Sync media toggle after login")
        for id in ["settings-sync-now", "settings-logout"] {
            let row = app.buttons[id]
            scrollTo(row)
            XCTAssertLessThan(abs(row.frame.height - mediaToggle.frame.height), 4, "\(id) row height matches toggle row")
        }
        let backup = app.buttons["Back up now"]
        scrollTo(backup)
        XCTAssertLessThan(abs(backup.frame.height - mediaToggle.frame.height), 4, "Back up now row height matches toggle row")
        shot("57-signed-in")
    }

    func testLargestTextSize() {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        sleep(4)
        shot("60-home-xxxl")
        app.buttons["Start review"].firstMatch.tap()
        let card = app.descendants(matching: .any)["review-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 20), "review card exists")
        XCTAssertGreaterThan(card.frame.height, 120, "card has room at XXXL")
        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 20), "card web view exists")
        XCTAssertTrue(web.staticTexts.firstMatch.waitForExistence(timeout: 20), "question text is rendered")
        sleep(1)
        shot("61-review-xxxl")
        XCTAssertTrue(app.buttons["Show answer"].firstMatch.exists, "Show answer capsule at XXXL")
        XCTAssertFalse(app.buttons["grade-good"].exists, "no grade buttons before reveal")
        card.tap()
        XCTAssertTrue(app.buttons["grade-again"].waitForExistence(timeout: 10))
        for name in ["again", "hard", "good", "easy"] {
            let b = app.buttons["grade-\(name)"]
            XCTAssertGreaterThanOrEqual(b.frame.height, 44, "\(name) is at least 44 pt")
        }
        let close = app.buttons["review-close"], undo = app.buttons["review-undo"]
        XCTAssertFalse(close.frame.intersects(undo.frame), "close and undo don't overlap")
        shot("62-review-xxxl-answer")
    }
}
