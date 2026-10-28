import XCTest
@testable import Cornhub

final class StatsDeckNameTests: XCTestCase {
    func testLeafAndParentFromNestedPath() {
        let deck = StatsDeck(id: 1, name: "A::B::C")
        XCTAssertEqual(deck.leafName, "C")
        XCTAssertEqual(deck.parentPath, "A › B")
        XCTAssertEqual(deck.depth, 2)
    }

    func testTopLevelDeckHasNoParent() {
        let deck = StatsDeck(id: 2, name: "Mandarin")
        XCTAssertEqual(deck.leafName, "Mandarin")
        XCTAssertNil(deck.parentPath)
        XCTAssertEqual(deck.depth, 0)
    }
}
