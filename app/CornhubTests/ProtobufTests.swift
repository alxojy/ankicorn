import SwiftProtobuf
import XCTest
@testable import Cornhub

final class ProtobufTests: XCTestCase {
    func testGeneratedMessageRoundTrips() throws {
        var request = Anki_Collection_OpenCollectionRequest()
        request.collectionPath = "/tmp/a.anki2"
        request.mediaFolderPath = "/tmp/a.media"
        request.mediaDbPath = "/tmp/a.media.db2"
        let decoded = try Anki_Collection_OpenCollectionRequest(serializedBytes: request.serializedData())
        XCTAssertEqual(decoded, request)
    }

    func testDecodesKnownWireBytes() throws {
        // BackendError { message = "boom" (field 1), kind = DB_ERROR (field 2, value 5) }
        let wire = Data([0x0A, 0x04, 0x62, 0x6F, 0x6F, 0x6D, 0x10, 0x05])
        let proto = try Anki_Backend_BackendError(serializedBytes: wire)
        XCTAssertEqual(proto.message, "boom")
        XCTAssertEqual(proto.kind, .dbError)
    }
}
