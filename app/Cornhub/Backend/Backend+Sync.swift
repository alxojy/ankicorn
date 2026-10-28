import Foundation

extension Backend {
    /// `sync_login`: exchanges AnkiWeb credentials for an hkey. Credentials are never stored by the app.
    func syncLogin(username: String, password: String) throws -> Anki_Sync_SyncAuth {
        var request = Anki_Sync_SyncLoginRequest()
        request.username = username
        request.password = password
        return try call(service: ServiceIndex.Sync.service, method: ServiceIndex.Sync.syncLogin, request)
    }

    /// `sync_collection`: a normal sync, or a report that a full upload or download is required.
    func syncCollection(auth: Anki_Sync_SyncAuth) throws -> Anki_Sync_SyncCollectionResponse {
        var request = Anki_Sync_SyncCollectionRequest()
        request.auth = auth
        request.syncMedia = false
        return try call(service: ServiceIndex.Sync.service, method: ServiceIndex.Sync.syncCollection, request)
    }

    /// `sync_media`.
    func syncMedia(auth: Anki_Sync_SyncAuth) throws {
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Sync.service, method: ServiceIndex.Sync.syncMedia, auth)
    }

    /// `full_upload_or_download`: replaces the server (upload) or this collection (download). The engine reopens
    /// the collection itself, even when the transfer fails, so the caller must not open it again.
    func fullUploadOrDownload(auth: Anki_Sync_SyncAuth, upload: Bool, serverUsn: Int32?) throws {
        var request = Anki_Sync_FullUploadOrDownloadRequest()
        request.auth = auth
        request.upload = upload
        if let serverUsn { request.serverUsn = serverUsn }
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Sync.service, method: ServiceIndex.Sync.fullUploadOrDownload, request)
    }

    /// `latest_progress`: readable while a sync runs because it skips the serial queue.
    nonisolated func latestProgress() throws -> Anki_Collection_Progress {
        try callConcurrently(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.latestProgress,
            Anki_Generic_Empty())
    }

    /// `create_backup`: the engine decides whether one is due unless `force`. Returns true if one was started.
    @discardableResult
    func createBackup(folder: URL, force: Bool, wait: Bool) throws -> Bool {
        var request = Anki_Collection_CreateBackupRequest()
        request.backupFolder = folder.path
        request.force = force
        request.waitForCompletion = wait
        let result: Anki_Generic_Bool = try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.createBackup, request)
        return result.val
    }
}

extension Backend {
    /// `get_preferences`.
    func getPreferences() throws -> Anki_Config_Preferences {
        try call(
            service: ServiceIndex.Config.service, method: ServiceIndex.Config.getPreferences, Anki_Generic_Empty())
    }

    /// `set_preferences`.
    func setPreferences(_ preferences: Anki_Config_Preferences) throws {
        let _: Anki_Collection_OpChanges = try call(
            service: ServiceIndex.Config.service, method: ServiceIndex.Config.setPreferences, preferences)
    }
}
