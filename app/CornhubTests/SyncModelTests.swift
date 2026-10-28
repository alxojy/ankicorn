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

/// Set from `withObservationTracking`'s Sendable onChange.
final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    var value: Bool { lock.withLock { flag } }
    func set() { lock.withLock { flag = true } }
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

    private func normal(_ stage: String, added: String = "", removed: String = "") -> Anki_Collection_Progress {
        var progress = Anki_Collection_Progress()
        var value = Anki_Collection_Progress.NormalSync()
        value.stage = stage
        value.added = added
        value.removed = removed
        progress.normalSync = value
        return progress
    }

    func testNormalSyncStageIsNotPrefixed() {
        XCTAssertEqual(SyncModel.describe(normal("Syncing...")), "Syncing…")
        XCTAssertEqual(SyncModel.describe(normal("Checking...")), "Checking…")
        XCTAssertNil(SyncModel.describe(normal("")))
    }

    func testAddedAndRemovedLinesPassThroughUnlessZero() {
        XCTAssertEqual(SyncModel.describeCounts(normal("Syncing...", added: "Added/modified: 3↓ 2↑", removed: "Removed: 0↓ 0↑")),
                       "Added/modified: 3↓ 2↑")
        XCTAssertNil(SyncModel.describeCounts(normal("Syncing...", added: "Added/modified: 0↓ 0↑", removed: "")))
    }

    func testMediaProgressTextPassesThrough() {
        var progress = Anki_Collection_Progress()
        var media = Anki_Sync_MediaSyncProgress()
        media.checked = "Checked: 12"
        media.added = "Added: 2↓ 1↑"
        progress.mediaSync = media
        XCTAssertEqual(SyncModel.describe(progress), "Checked: 12")
        XCTAssertEqual(SyncModel.describeCounts(progress), "Added: 2↓ 1↑")
        progress.mediaSync = Anki_Sync_MediaSyncProgress()
        XCTAssertEqual(SyncModel.describe(progress), "Syncing media…")
    }

    func testSignInStateNotifiesObservers() async throws {
        AccountStore().clear()
        defer { AccountStore().clear() }
        let model = SyncModel(stubLogin: true)  // also clears the saved last-sync time
        XCTAssertFalse(model.isSignedIn)
        XCTAssertEqual(model.statusText, "Not signed in")

        let signedInChanged = Flag()
        withObservationTracking { _ = model.isSignedIn; _ = model.statusText } onChange: { signedInChanged.set() }
        try await model.login(backend: try Backend(), username: "testuser", password: "x")
        XCTAssertTrue(signedInChanged.value, "login notifies observers of isSignedIn and statusText")
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(model.statusText, "Not synced yet")

        let signedOutChanged = Flag()
        withObservationTracking { _ = model.isSignedIn; _ = model.statusText } onChange: { signedOutChanged.set() }
        model.logout()
        XCTAssertTrue(signedOutChanged.value, "logout notifies observers")
        XCTAssertFalse(model.isSignedIn)
    }
}
