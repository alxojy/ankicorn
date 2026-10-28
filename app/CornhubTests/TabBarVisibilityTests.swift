import XCTest
@testable import Cornhub

final class TabBarVisibilityTests: XCTestCase {
    func testEachReasonAloneHidesTheBar() {
        var v = TabBarVisibility()
        XCTAssertFalse(v.hidden)
        v.selectionMode = true
        XCTAssertTrue(v.hidden)
        v.selectionMode = false
        v.keyboardUp = true
        XCTAssertTrue(v.hidden)
        v.keyboardUp = false
        v.scrolled(offset: 0, maxOffset: 1000)
        v.scrolled(offset: 100, maxOffset: 1000)
        XCTAssertTrue(v.hidden)
    }

    func testScrollUpTopAndEndShowTheBar() {
        var v = TabBarVisibility()
        v.scrolled(offset: 100, maxOffset: 1000)
        XCTAssertTrue(v.hidden)
        v.scrolled(offset: 80, maxOffset: 1000)
        XCTAssertFalse(v.hidden, "scrolling up shows the bar")
        v.scrolled(offset: 200, maxOffset: 1000)
        XCTAssertTrue(v.hidden)
        v.scrolled(offset: 0, maxOffset: 1000)
        XCTAssertFalse(v.hidden, "top shows the bar")
        v.scrolled(offset: 300, maxOffset: 1000)
        v.scrolled(offset: 1000, maxOffset: 1000)
        XCTAssertFalse(v.hidden, "end shows the bar")
    }

    func testSmallJittersDoNotToggle() {
        var v = TabBarVisibility()
        v.scrolled(offset: 100, maxOffset: 1000)
        v.scrolled(offset: 106, maxOffset: 1000)
        XCTAssertFalse(v.hidden)
        v.scrolled(offset: 150, maxOffset: 1000)
        XCTAssertTrue(v.hidden)
        v.scrolled(offset: 144, maxOffset: 1000)
        XCTAssertTrue(v.hidden)
    }

    func testVoiceOverKeepsBarShown() {
        var v = TabBarVisibility(voiceOverRunning: true)
        v.scrolled(offset: 100, maxOffset: 1000)
        v.scrolled(offset: 300, maxOffset: 1000)
        XCTAssertFalse(v.hidden)
    }

    func testResetShowsTheBar() {
        var v = TabBarVisibility()
        v.scrolled(offset: 50, maxOffset: 1000)
        v.scrolled(offset: 200, maxOffset: 1000)
        XCTAssertTrue(v.hidden)
        v.reset()
        XCTAssertFalse(v.hidden)
    }
}
