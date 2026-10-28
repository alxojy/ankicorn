import XCTest
@testable import Cornhub

/// An engine that records calls and answers a sync with a full-transfer requirement.
final class FakeSyncEngine: SyncEngine, @unchecked Sendable {
    var fullTransfers: [Bool] = []
    var mediaSyncs = 0
    var failMedia = false
    var failTransfer = false

    func syncCollection(auth: Anki_Sync_SyncAuth) async throws -> Anki_Sync_SyncCollectionResponse {
        var response = Anki_Sync_SyncCollectionResponse()
        response.required = .fullSync
        response.serverMediaUsn = 7
        return response
    }

    func syncMedia(auth: Anki_Sync_SyncAuth) async throws {
        mediaSyncs += 1
        if failMedia { throw BackendError(kind: .invalidInput, message: "media offline") }
    }

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
        let choice = try XCTUnwrap(model.fullSyncChoice)
        XCTAssertTrue(choice.canDownload && choice.canUpload)
        model.cancelFullSync()  // the dialog's dismissal setter
        XCTAssertNil(model.fullSyncChoice)
        await model.resolveFullSync(choice, upload: false, backend: engine)
        XCTAssertEqual(engine.fullTransfers, [false])
        XCTAssertEqual(model.phase, .idle)
        XCTAssertNotNil(model.lastSynced)
    }

    func testUploadRunsAfterTheDialogDismisses() async throws {
        let engine = FakeSyncEngine()
        let model = await modelAwaitingChoice(engine)
        let choice = try XCTUnwrap(model.fullSyncChoice)
        model.cancelFullSync()
        await model.resolveFullSync(choice, upload: true, backend: engine)
        XCTAssertEqual(engine.fullTransfers, [true])
    }

    /// The engine reopens the collection itself, so the model only refreshes the screens (once), never reopens.
    func testFinishRefreshesOnceAndSyncsMedia() async throws {
        let engine = FakeSyncEngine()
        let model = await modelAwaitingChoice(engine)
        model.syncMediaEnabled = true
        var refreshes = 0
        model.didFinish = { refreshes += 1 }
        let choice = try XCTUnwrap(model.fullSyncChoice)
        await model.resolveFullSync(choice, upload: false, backend: engine)
        XCTAssertEqual(refreshes, 1)
        XCTAssertEqual(engine.mediaSyncs, 1)
    }

    func testNoMediaSyncWhenSwitchedOff() async throws {
        let engine = FakeSyncEngine()
        let model = await modelAwaitingChoice(engine)
        model.syncMediaEnabled = false
        let choice = try XCTUnwrap(model.fullSyncChoice)
        await model.resolveFullSync(choice, upload: false, backend: engine)
        XCTAssertEqual(engine.mediaSyncs, 0)
        model.syncMediaEnabled = true
    }

    func testFailureShowsEngineErrorAndStillRefreshes() async throws {
        let engine = FakeSyncEngine()
        engine.failTransfer = true
        let model = await modelAwaitingChoice(engine)
        var refreshes = 0
        model.didFinish = { refreshes += 1 }
        let choice = try XCTUnwrap(model.fullSyncChoice)
        await model.resolveFullSync(choice, upload: false, backend: engine)
        XCTAssertEqual(model.phase, .failed("network down"))
        XCTAssertEqual(engine.mediaSyncs, 0)
        XCTAssertEqual(refreshes, 1)
    }

    func testCancelClearsTheChoiceWithoutTransferring() async throws {
        let engine = FakeSyncEngine()
        let model = await modelAwaitingChoice(engine)
        model.cancelFullSync()
        XCTAssertNil(model.fullSyncChoice)
        XCTAssertEqual(model.phase, .idle)
        XCTAssertTrue(engine.fullTransfers.isEmpty)
    }

    func testProgressTextNamesTheDirection() {
        var progress = Anki_Collection_Progress()
        var full = Anki_Collection_Progress.FullSync()
        full.transferred = 42
        full.total = 100
        progress.fullSync = full
        XCTAssertEqual(SyncModel.describe(progress, transfer: "Downloading"), "Downloading 42%")
    }

    func testSignInStateNotifiesObservers() async throws {
        AccountStore().clear()
        defer { AccountStore().clear() }
        let model = SyncModel(stubLogin: true)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertEqual(model.statusText, "Not signed in")

        var signedInChanged = false
        withObservationTracking { _ = model.isSignedIn; _ = model.statusText } onChange: { signedInChanged = true }
        try await model.login(backend: try Backend(), username: "testuser", password: "x")
        XCTAssertTrue(signedInChanged, "login notifies observers of isSignedIn and statusText")
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.statusText, "Not synced yet")

        var signedOutChanged = false
        withObservationTracking { _ = model.isSignedIn; _ = model.statusText } onChange: { signedOutChanged = true }
        model.logout()
        XCTAssertTrue(signedOutChanged, "logout notifies observers")
        XCTAssertFalse(model.isSignedIn)
    }
}
