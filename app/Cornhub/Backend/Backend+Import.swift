import Foundation

/// What an import changed, for the result summary.
struct ImportSummary: Equatable {
    var new = 0
    var updated = 0
    var duplicate = 0
    var skipped = 0
    /// A `.colpkg` replaced the whole collection.
    var replacedCollection = false

    init(replacedCollection: Bool = false) {
        self.replacedCollection = replacedCollection
    }

    init(_ log: Anki_ImportExport_ImportResponse.Log) {
        new = log.new.count
        updated = log.updated.count
        duplicate = log.duplicate.count
        skipped = log.conflicting.count + log.missingNotetype.count + log.missingDeck.count
            + log.emptyFirstField.count + log.firstFieldMatch.count
    }

    var lines: [String] {
        if replacedCollection { return ["Collection replaced"] }
        var lines = ["\(new) new notes"]
        if updated > 0 { lines.append("\(updated) updated") }
        if duplicate > 0 { lines.append("\(duplicate) duplicates") }
        if skipped > 0 { lines.append("\(skipped) skipped") }
        return lines
    }
}

extension Backend {
    /// `import_anki_package`: merges an `.apkg` into the open collection.
    func importAnkiPackage(path: URL) throws -> ImportSummary {
        var options = Anki_ImportExport_ImportAnkiPackageOptions()
        options.mergeNotetypes = true
        options.withScheduling = true
        options.withDeckConfigs = true
        var request = Anki_ImportExport_ImportAnkiPackageRequest()
        request.packagePath = path.path
        request.options = options
        let response: Anki_ImportExport_ImportResponse = try call(
            service: ServiceIndex.ImportExport.service, method: ServiceIndex.ImportExport.importAnkiPackage, request)
        return ImportSummary(response.log)
    }

    /// `import_collection_package`: replaces the collection with a `.colpkg`. The collection must be closed
    /// for the call, so it is closed first and opened again afterwards, even when the import fails.
    func importCollectionPackage(path: URL, collection: URL) throws -> ImportSummary {
        try closeCollection()
        let base = collection.deletingPathExtension()
        var request = Anki_ImportExport_ImportCollectionPackageRequest()
        request.colPath = collection.path
        request.backupPath = path.path
        request.mediaFolder = base.appendingPathExtension("media").path
        request.mediaDb = base.appendingPathExtension("media.db2").path
        do {
            let _: Anki_Generic_Empty = try call(
                service: ServiceIndex.ImportExport.service,
                method: ServiceIndex.ImportExport.importCollectionPackage, request)
        } catch {
            try? openCollection(path: collection)
            throw error
        }
        try openCollection(path: collection)
        return ImportSummary(replacedCollection: true)
    }
}
