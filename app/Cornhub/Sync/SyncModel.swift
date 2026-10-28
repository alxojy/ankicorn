import Foundation
import Observation

/// What the engine needs the user to decide before a full sync.
struct FullSyncChoice: Equatable {
    var canUpload: Bool
    var canDownload: Bool
    var serverUsn: Int32
    var auth: Anki_Sync_SyncAuth
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
    /// The engine's change counts ("Added/modified: 3↓ 2↑"), shown muted under the status while syncing.
    private(set) var detail: String?
    private(set) var username: String?
    /// Observed copy of "an hkey is stored", so screens redraw on login and logout (the Keychain is not observable).
    private(set) var isSignedIn: Bool
    private(set) var lastSynced: Date?
    var fullSyncChoice: FullSyncChoice?
    var syncMediaEnabled: Bool { didSet { defaults.set(syncMediaEnabled, forKey: Keys.media) } }
    var syncOnOpen: Bool { didSet { defaults.set(syncOnOpen, forKey: Keys.onOpen) } }

    /// Refreshes the screens after a sync; the engine itself reopens the collection after a full transfer.
    var didFinish: () async -> Void = {}

    private let store = AccountStore()
    /// Test seam: logs in without the network, saving an invented hkey.
    private let stubLogin: Bool
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let last = "sync.lastSynced"
        static let media = "sync.media"
        static let onOpen = "sync.onOpen"
        static let lastBackup = "backup.last"
    }

    init(stubLogin: Bool = false) {
        self.stubLogin = stubLogin
        if stubLogin {
            store.clear()
            defaults.removeObject(forKey: Keys.last)
        }
        username = store.username
        isSignedIn = store.hkey != nil
        lastSynced = defaults.object(forKey: Keys.last) as? Date
        syncMediaEnabled = defaults.object(forKey: Keys.media) as? Bool ?? true
        syncOnOpen = defaults.bool(forKey: Keys.onOpen)
    }

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
        var hkey = "stub-hkey"
        if !stubLogin { hkey = try await backend.syncLogin(username: username, password: password).hkey }
        store.save(hkey: hkey, username: username)
        self.username = username
        isSignedIn = true
        phase = .idle
    }

    func logout() {
        store.clear()
        username = nil
        isSignedIn = false
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
        detail = nil
        phase = .syncing("Syncing…")
        let poller = startProgress(backend)
        defer { poller.cancel() }
        do {
            let response = try await backend.syncCollection(auth: auth)
            if response.hasNewEndpoint { auth.endpoint = response.newEndpoint }
            switch response.required {
            case .fullSync, .fullDownload, .fullUpload:
                fullSyncChoice = FullSyncChoice(
                    canUpload: response.required != .fullDownload, canDownload: response.required != .fullUpload,
                    serverUsn: response.serverMediaUsn, auth: auth)
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

    /// The user's answer to the full-sync prompt. The choice is passed in because the dialog clears
    /// `fullSyncChoice` as it dismisses, before the tapped button's action runs. Takes a backup first, then
    /// transfers; the engine reopens the collection itself, so this only refreshes the screens.
    func resolveFullSync(_ choice: FullSyncChoice, upload: Bool, backend: any SyncEngine) async {
        guard !isSyncing else { return }
        fullSyncChoice = nil
        let verb = upload ? "Uploading" : "Downloading"
        phase = .syncing("\(verb)…")
        let poller = startProgress(backend, transfer: verb)
        defer { poller.cancel() }
        do {
            _ = try? await backend.createBackup(folder: Self.backupsFolder, force: true, wait: true)
            try await backend.fullUploadOrDownload(auth: choice.auth, upload: upload, serverUsn: nil)
        } catch {
            fail(error)
            await didFinish()
            return
        }
        do {
            if syncMediaEnabled {
                phase = .syncing("Syncing media…")
                try await backend.syncMedia(auth: choice.auth)
            }
            finish()
        } catch {
            fail(error)
        }
        await didFinish()
    }

    /// Clears the prompt without transferring anything (Cancel, or a dismissal with no choice made).
    func cancelFullSync() {
        fullSyncChoice = nil
        if !isSyncing { phase = .idle }
    }

    /// Shows an error for a full-sync answer that cannot run (never a silent return).
    func failFullSync(_ message: String) {
        fullSyncChoice = nil
        phase = .failed(message)
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

    private func finish() {
        detail = nil
        lastSynced = Date()
        defaults.set(lastSynced, forKey: Keys.last)
        phase = .idle
    }

    private func fail(_ error: Error) {
        detail = nil
        phase = .failed(error.localizedDescription)
    }

    /// Polls `latest_progress` while a long call occupies the backend.
    private func startProgress(_ backend: any SyncEngine, transfer: String? = nil) -> Task<Void, Never> {
        Task { [weak self] in
            while !Task.isCancelled {
                if let progress = try? backend.latestProgress(), let text = Self.describe(progress, transfer: transfer) {
                    self?.updateDetail(text)
                    self?.updateCounts(Self.describeCounts(progress))
                }
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    private func updateDetail(_ text: String) {
        if case .syncing = phase { phase = .syncing(text) }
    }

    private func updateCounts(_ text: String?) {
        if case .syncing = phase { detail = text }
    }

    nonisolated static func describe(_ progress: Anki_Collection_Progress, transfer: String? = nil) -> String? {
        switch progress.value {
        case .normalSync(let value)?: return value.stage.isEmpty ? nil : Self.tidy(value.stage)
        case .fullSync(let value)? where value.total > 0:
            return "\(transfer ?? "Transferring") \(Int(value.transferred) * 100 / Int(value.total))%"
        case .mediaSync(let value)?: return value.checked.isEmpty ? "Syncing media…" : Self.tidy(value.checked)
        default: return nil
        }
    }

    /// The engine's added/removed lines, or nil when there is nothing but zeros to say.
    nonisolated static func describeCounts(_ progress: Anki_Collection_Progress) -> String? {
        let lines: [String]
        switch progress.value {
        case .normalSync(let value)?: lines = [value.added, value.removed]
        case .mediaSync(let value)?: lines = [value.added, value.removed]
        default: return nil
        }
        let shown = lines.map { Self.tidy($0) }.filter { line in
            !line.isEmpty && line.contains { $0.isNumber && $0 != "0" }
        }
        return shown.isEmpty ? nil : shown.joined(separator: " · ")
    }

    /// The engine ends its phrases with three dots; Ink type uses the single character.
    nonisolated private static func tidy(_ text: String) -> String {
        var text = text.trimmingCharacters(in: .whitespaces)
        if text.hasSuffix("...") { text = String(text.dropLast(3)) + "…" }
        return text
    }
}
