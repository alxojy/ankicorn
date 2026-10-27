import Foundation

/// Which notes or cards an export covers.
enum ExportScope: Hashable {
    case wholeCollection
    case deck(Int64)

    fileprivate var limit: Anki_ImportExport_ExportLimit {
        var limit = Anki_ImportExport_ExportLimit()
        switch self {
        case .wholeCollection: limit.wholeCollection = Anki_Generic_Empty()
        case .deck(let id): limit.deckID = id
        }
        return limit
    }
}

extension Backend {
    // MARK: CSV import

    /// `get_csv_metadata`: the engine's guess at delimiter, columns, notetype and deck for a file.
    func csvMetadata(path: URL) throws -> Anki_ImportExport_CsvMetadata {
        var request = Anki_ImportExport_CsvMetadataRequest()
        request.path = path.path
        return try call(
            service: ServiceIndex.ImportExport.service, method: ServiceIndex.ImportExport.getCsvMetadata, request)
    }

    /// `import_csv`: imports with the given (possibly adjusted) metadata.
    func importCsv(path: URL, metadata: Anki_ImportExport_CsvMetadata) throws -> ImportSummary {
        var request = Anki_ImportExport_ImportCsvRequest()
        request.path = path.path
        request.metadata = metadata
        let response: Anki_ImportExport_ImportResponse = try call(
            service: ServiceIndex.ImportExport.service, method: ServiceIndex.ImportExport.importCsv, request)
        return ImportSummary(response.log)
    }

    // MARK: Export

    /// `export_anki_package`: writes an `.apkg`. Returns how many notes were exported.
    @discardableResult
    func exportAnkiPackage(to path: URL, scope: ExportScope, withScheduling: Bool, withMedia: Bool) throws -> Int {
        var options = Anki_ImportExport_ExportAnkiPackageOptions()
        options.withScheduling = withScheduling
        options.withDeckConfigs = withScheduling
        options.withMedia = withMedia
        var request = Anki_ImportExport_ExportAnkiPackageRequest()
        request.outPath = path.path
        request.options = options
        request.limit = scope.limit
        let count: Anki_Generic_UInt32 = try call(
            service: ServiceIndex.ImportExport.service, method: ServiceIndex.ImportExport.exportAnkiPackage, request)
        return Int(count.val)
    }

    /// `export_collection_package`: writes a `.colpkg`. The engine closes the collection for the export, so it
    /// is opened again afterwards, even when the export fails.
    func exportCollectionPackage(to path: URL, collection: URL, includeMedia: Bool) throws {
        var request = Anki_ImportExport_ExportCollectionPackageRequest()
        request.outPath = path.path
        request.includeMedia = includeMedia
        request.legacy = false
        do {
            let _: Anki_Generic_Empty = try call(
                service: ServiceIndex.ImportExport.service,
                method: ServiceIndex.ImportExport.exportCollectionPackage, request)
        } catch {
            try? openCollection(path: collection)
            throw error
        }
        try openCollection(path: collection)
    }

    /// `export_note_csv`.
    @discardableResult
    func exportNoteCsv(to path: URL, scope: ExportScope) throws -> Int {
        var request = Anki_ImportExport_ExportNoteCsvRequest()
        request.outPath = path.path
        request.withHtml = true
        request.withTags = true
        request.withDeck = true
        request.withNotetype = true
        request.limit = scope.limit
        let count: Anki_Generic_UInt32 = try call(
            service: ServiceIndex.ImportExport.service, method: ServiceIndex.ImportExport.exportNoteCsv, request)
        return Int(count.val)
    }

    /// `export_card_csv`.
    @discardableResult
    func exportCardCsv(to path: URL, scope: ExportScope) throws -> Int {
        var request = Anki_ImportExport_ExportCardCsvRequest()
        request.outPath = path.path
        request.withHtml = true
        request.limit = scope.limit
        let count: Anki_Generic_UInt32 = try call(
            service: ServiceIndex.ImportExport.service, method: ServiceIndex.ImportExport.exportCardCsv, request)
        return Int(count.val)
    }

    // MARK: Tools

    /// `check_database`: repairs what it can and returns the problems it found.
    func checkDatabase() throws -> [String] {
        let response: Anki_Collection_CheckDatabaseResponse = try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.checkDatabase,
            Anki_Generic_Empty())
        return response.problems
    }

    /// `check_media`: unused and missing files.
    func checkMedia() throws -> Anki_Media_CheckMediaResponse {
        try call(
            service: ServiceIndex.Media.service, method: ServiceIndex.Media.checkMedia, Anki_Generic_Empty())
    }

    /// `trash_media_files`: moves files to the media trash.
    func trashMediaFiles(_ names: [String]) throws {
        var request = Anki_Media_TrashMediaFilesRequest()
        request.fnames = names
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Media.service, method: ServiceIndex.Media.trashMediaFiles, request)
    }

    /// `restore_trash`.
    func restoreMediaTrash() throws {
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Media.service, method: ServiceIndex.Media.restoreTrash, Anki_Generic_Empty())
    }

    /// `empty_trash`: deletes the trashed files for good.
    func emptyMediaTrash() throws {
        let _: Anki_Generic_Empty = try call(
            service: ServiceIndex.Media.service, method: ServiceIndex.Media.emptyTrash, Anki_Generic_Empty())
    }

    /// `get_empty_cards`.
    func emptyCardsReport() throws -> Anki_CardRendering_EmptyCardsReport {
        try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.getEmptyCards,
            Anki_Generic_Empty())
    }

    /// `remove_cards`.
    func removeCards(_ ids: [Int64]) throws {
        var request = Anki_Cards_RemoveCardsRequest()
        request.cardIds = ids
        let _: Anki_Collection_OpChangesWithCount = try call(
            service: ServiceIndex.Cards.service, method: ServiceIndex.Cards.removeCards, request)
    }
}
