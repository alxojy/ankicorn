import XCTest
@testable import Cornhub

/// An engine that records calls and answers a sync with a full-transfer requirement.
final class FakeSyncEngine: SyncEngine, @unchecked Sendable {
    var fullTransfers: [Bool] = []
    var mediaSyncs = 0
    var failTransfer = false

    func syncCollection(auth: Anki_Sync_SyncAuth) async throws -> Anki_Sync_SyncCollectionResponse {
        var response = Anki_Sync_SyncCollectionResponse()
        response.required = .fullSync
        response.serverMediaUsn = 7
        return response
    }

    func syncMedia(auth: Anki_Sync_SyncAuth) async throws { mediaSyncs += 1 }

    func fullUploadOrDownload(auth: Anki_Sync_SyncAuth, upload: Bool, serverUsn: Int32?) async throws {
        fullTransfers.append(upload)
        if failTransfer { throw BackendError(kind: .invalidInput, message: "network down") }
    }

    func createBackup(folder: URL, force: Bool, wait: Bool) async throws -> Bool { true }
    func latestProgress() throws -> Anki_Collection_Progress { Anki_Collection_Progress() }
}

@MainActor
final class SyncModelTests: XCTestCase {
    /// A signed-in model that has just been told a full transfer is needed.
    private func modelAwaitingChoice(_ engine: FakeSyncEngine) async -> SyncModel {
        AccountStore().save(hkey: "testkey", username: "testuser")
        let model = SyncModel()
        await model.sync(backend: engine)
        return model
    }

    override func tearDown() async throws { AccountStore().clear() }

    /// The confirmation dialog dismisses itself (clearing the choice) before the tapped button's action runs.
    func testDownloadRunsAfterTheDialogDismisses() async throws {
        let engine = FakeSyncEngine()
        let model = await modelAwaitingChoice(engine)
        XCTAssertNotNil(model.fullSyncChoice)
        model.cancelFullSync()
        await model.resolveFullSync(upload: false, backend: engine)
        XCTAssertEqual(engine.fullTransfers, [false])
    }
}
