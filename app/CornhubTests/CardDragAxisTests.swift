import CoreGraphics
import XCTest

@testable import Cornhub

final class CardDragAxisTests: XCTestCase {
    func testTinyMovementIsUndecided() {
        XCTAssertNil(CardDragAxis.decide(CGSize(width: 3, height: 5)))
    }

    func testMostlyVerticalScrolls() {
        XCTAssertEqual(CardDragAxis.decide(CGSize(width: 4, height: -30)), .vertical)
    }

    func testMostlyHorizontalGrades() {
        XCTAssertEqual(CardDragAxis.decide(CGSize(width: 40, height: 10)), .horizontal)
        XCTAssertEqual(CardDragAxis.decide(CGSize(width: -40, height: -39)), .horizontal)
    }
}
