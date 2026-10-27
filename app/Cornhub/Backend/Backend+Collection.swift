import Foundation

extension Backend {
    /// `open_collection`: opens (creating if needed) the collection at `path`, with media beside it.
    func openCollection(path: URL) throws {
        var request = Anki_Collection_OpenCollectionRequest()
        request.collectionPath = path.path
        let base = path.deletingPathExtension()
        request.mediaFolderPath = base.appendingPathExtension("media").path
        request.mediaDbPath = base.appendingPathExtension("media.db2").path
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.openCollection, request)
    }

    /// `close_collection`.
    func closeCollection(downgradeToSchema11: Bool = false) throws {
        var request = Anki_Collection_CloseCollectionRequest()
        request.downgradeToSchema11 = downgradeToSchema11
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.closeCollection, request)
    }
}
