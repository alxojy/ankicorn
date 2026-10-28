import XCTest
@testable import Cornhub

final class StudyStreakTests: XCTestCase {
    func testNoReviewsIsZero() {
        XCTAssertEqual(StudyStreak.days([0, 0, 0]), 0)
        XCTAssertEqual(StudyStreak.days([]), 0)
    }

    func testRunEndingToday() {
        XCTAssertEqual(StudyStreak.days([0, 4, 2, 7]), 3)
    }

    func testRunEndingYesterdayStillCounts() {
        XCTAssertEqual(StudyStreak.days([0, 4, 2, 0]), 2)
    }

    func testRunBrokenYesterdayIsZero() {
        XCTAssertEqual(StudyStreak.days([5, 5, 0, 0]), 0)
    }
}
