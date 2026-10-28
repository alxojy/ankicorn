import Foundation
import Observation

/// What the engine needs the user to decide before a full sync.
struct FullSyncChoice: Equatable {
    var canUpload: Bool
    var canDownload: Bool
    var serverUsn: Int32
}

/// The engine calls a sync needs; `Backend` is the real one and tests substitute a fake.
protocol SyncEngine: Sendable {
    func syncCollection(auth: Anki_Sync_SyncAuth) async throws -> Anki_Sync_SyncCollectionResponse
    func syncMedia(auth: Anki_Sync_SyncAuth) async throws
    func fullUploadOrDownload(auth: Anki_Sync_SyncAuth, upload: Bool, serverUsn: Int32?) async throws
    func createBackup(folder: URL, force: Bool, wait: Bool) async throws -> Bool
    nonisolated func latestProgress() throws -> Anki_Collection_Progress
}

extension Backend: SyncEngine {}

/// Drives login, sync, the full-sync choice and backups. Shared by the Decks tab and Settings.
@MainActor
@Observable
final class SyncModel {
    enum Phase: Equatable {
        case idle
        case syncing(String)
        case failed(String)
    }

    private(set) var phase = Phase.idle
    private(set) var username: String?
    private(set) var lastSynced: Date?
    var fullSyncChoice: FullSyncChoice?
    var syncMediaEnabled: Bool { didSet { defaults.set(syncMediaEnabled, forKey: Keys.media) } }
    var syncOnOpen: Bool { didSet { defaults.set(syncOnOpen, forKey: Keys.onOpen) } }

    /// Reopens the collection after a full transfer closed it, then refreshes the screens.
    var reopenCollection: () async throws -> Void = {}
    var didFinish: () async -> Void = {}

    private let store = AccountStore()
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let last = "sync.lastSynced"
        static let media = "sync.media"
        static let onOpen = "sync.onOpen"
        static let lastBackup = "backup.last"
    }

    init() {
        username = store.username
        lastSynced = defaults.object(forKey: Keys.last) as? Date
        syncMediaEnabled = defaults.object(forKey: Keys.media) as? Bool ?? true
        syncOnOpen = defaults.bool(forKey: Keys.onOpen)
    }

    var isSignedIn: Bool { store.hkey != nil }
    var isSyncing: Bool { if case .syncing = phase { true } else { false } }

    /// "Synced 2 min ago" and friends; the quiet line under the date.
    var statusText: String {
        if case .syncing(let detail) = phase { return detail }
        if case .failed(let message) = phase { return message }
        guard isSignedIn else { return "Not signed in" }
        guard let lastSynced else { return "Not synced yet" }
        if Date().timeIntervalSince(lastSynced) < 60 { return "Synced just now" }
        return "Synced " + lastSynced.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))
    }

    var hasFailed: Bool { if case .failed = phase { true } else { false } }

    // MARK: Account

    func login(backend: Backend, username: String, password: String) async throws {
        let auth = try await backend.syncLogin(username: username, password: password)
        store.save(hkey: auth.hkey, username: username)
        self.username = username
        phase = .idle
    }

    func logout() {
        store.clear()
        username = nil
        lastSynced = nil
        defaults.removeObject(forKey: Keys.last)
        phase = .idle
    }

    // MARK: Sync

    /// Runs only from the user's own action (button, pull to refresh) or the opt-in sync-on-open setting.
    func sync(backend: any SyncEngine) async {
        guard !isSyncing, let hkey = store.hkey else { return }
        var auth = Anki_Sync_SyncAuth()
        auth.hkey = hkey
        phase = .syncing("Syncing…")
        let poller = startProgress(backend)
        defer { poller.cancel() }
        do {
            let response = try await backend.syncCollection(auth: auth)
            if response.hasNewEndpoint { auth.endpoint = response.newEndpoint }
            switch response.required {
            case .fullSync, .fullDownload, .fullUpload:
                pendingAuth = auth
                fullSyncChoice = FullSyncChoice(
                    canUpload: response.required != .fullDownload, canDownload: response.required != .fullUpload,
                    serverUsn: response.serverMediaUsn)
                phase = .idle
                return
            default:
                break
            }
            if syncMediaEnabled { try await backend.syncMedia(auth: auth) }
            finish()
            await backupIfDue(backend)
            await didFinish()
        } catch {
            fail(error)
        }
    }

    /// The user's answer to the full-sync prompt. Takes a backup first, then transfers and reopens.
    func resolveFullSync(upload: Bool, backend: any SyncEngine) async {
        guard let choice = fullSyncChoice, let auth = pendingAuth else { return }
        fullSyncChoice = nil
        phase = .syncing(upload ? "Uploading…" : "Downloading…")
        let poller = startProgress(backend)
        defer { poller.cancel() }
        do {
            try? await backend.createBackup(folder: Self.backupsFolder, force: true, wait: true)
            try await backend.fullUploadOrDownload(auth: auth, upload: upload, serverUsn: syncMediaEnabled ? choice.serverUsn : nil)
            try await reopenCollection()
            finish()
            await didFinish()
        } catch {
            try? await reopenCollection()
            fail(error)
        }
    }

    func cancelFullSync() {
        fullSyncChoice = nil
        pendingAuth = nil
        phase = .idle
    }

    // MARK: Backups

    nonisolated static var backupsFolder: URL {
        let url = URL.documentsDirectory.appending(path: "Backups")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Periodic backup: the engine throttles by its own interval, so this is safe to call often.
    func backupIfDue(_ backend: any SyncEngine) async {
        if (try? await backend.createBackup(folder: Self.backupsFolder, force: false, wait: false)) == true {
            defaults.set(Date(), forKey: Keys.lastBackup)
        }
    }

    func backupNow(_ backend: any SyncEngine) async {
        phase = .syncing("Backing up…")
        do {
            try await backend.createBackup(folder: Self.backupsFolder, force: true, wait: true)
            defaults.set(Date(), forKey: Keys.lastBackup)
            phase = .idle
        } catch {
            fail(error)
        }
    }

    var lastBackup: Date? { defaults.object(forKey: Keys.lastBackup) as? Date }

    // MARK: Private

    private var pendingAuth: Anki_Sync_SyncAuth?

    private func finish() {
        pendingAuth = nil
        lastSynced = Date()
        defaults.set(lastSynced, forKey: Keys.last)
        phase = .idle
    }

    private func fail(_ error: Error) {
        phase = .failed(error.localizedDescription)
    }

    /// Polls `latest_progress` while a long call occupies the backend.
    private func startProgress(_ backend: any SyncEngine) -> Task<Void, Never> {
        Task { [weak self] in
            while !Task.isCancelled {
                if let progress = try? backend.latestProgress(), let text = Self.describe(progress) {
                    self?.updateDetail(text)
                }
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    private func updateDetail(_ text: String) {
        if case .syncing = phase { phase = .syncing(text) }
    }

    nonisolated static func describe(_ progress: Anki_Collection_Progress) -> String? {
        switch progress.value {
        case .normalSync(let value)?: return value.stage.isEmpty ? nil : "Syncing \(value.stage)…"
        case .fullSync(let value)? where value.total > 0:
            return "Transferring \(Int(value.transferred) * 100 / Int(value.total))%"
        case .mediaSync?: return "Syncing media…"
        default: return nil
        }
    }
}
