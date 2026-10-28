import Foundation
import WebKit
import SwiftProtobuf

/// Hooks for the few desktop-only endpoints Anki's pages call (mediasrv.py's `post_handler_list`).
final class AnkiWebEvents: @unchecked Sendable {
    /// The deck options page finished loading.
    var onReady: @MainActor () -> Void = {}
    /// The page asks to be closed (saved, or the user confirmed discarding changes).
    var onClose: @MainActor () -> Void = {}
    var openLink: @MainActor (URL) -> Void = { _ in }
    /// The hosting web view, so the sheet's Done button can ask the page about unsaved changes.
    @MainActor weak var webView: WKWebView?
}

/// What a page gets back: an HTTP status and body. Empty bodies answer 204 like mediasrv.py.
struct AnkiWebResult: Equatable {
    var status: Int
    var body: Data
    var mime: String

    static let noContent = AnkiWebResult(status: 204, body: Data(), mime: "text/plain")
    static func binary(_ data: Data) -> AnkiWebResult {
        data.isEmpty ? .noContent : AnkiWebResult(status: 200, body: data, mime: "application/binary")
    }
    static func text(_ status: Int, _ text: String) -> AnkiWebResult {
        AnkiWebResult(status: status, body: Data(text.utf8), mime: "text/plain")
    }
}

/// Answers `POST /_anki/<method>`: engine methods go straight to rslib's `run_method`; the endpoints that are
/// desktop-only in mediasrv.py are ported here or refused deliberately.
final class AnkiWebAPI: @unchecked Sendable {
    /// Engine methods mediasrv.py exposes (`exposed_backend_list`) plus the ones its own handlers wrap.
    static let exposed: Set<String> = [
        "latestProgress", "getCustomColours",
        "getDeckNames", "getDeck",
        "i18nResources",
        "getCsvMetadata", "getImportAnkiPackagePresets", "importCsv", "importAnkiPackage", "importJsonFile",
        "importJsonString",
        "getFieldNames", "getNote", "newNote", "noteFieldsCheck", "defaultsForAdding", "defaultDeckForNotetype",
        "addNote", "updateNotes", "updateNotetype",
        "getNotetype", "getNotetypeNames", "getChangeNotetypeInfo", "getClozeFieldOrds",
        "cardStats", "getReviewLogs", "graphs", "getGraphPreferences", "setGraphPreferences",
        "completeTag",
        "getImageForOcclusion", "addImageOcclusionNote", "getImageOcclusionNote", "updateImageOcclusionNote",
        "getImageOcclusionFields",
        "computeFsrsParams", "computeOptimalRetention", "setWantsAbort", "evaluateParamsLegacy",
        "getOptimalRetentionParameters", "simulateFsrsReview", "simulateFsrsWorkload",
        "getIgnoredBeforeCount", "getRetentionWorkload",
        "encodeIriPaths", "decodeIriPaths", "htmlToTextLine",
        "setConfigJson", "getConfigBool",
        "addMediaFile", "addMediaFromPath", "addMediaFromUrl", "getAbsoluteMediaPath", "extractMediaFiles",
        "getCard",
        // wrapped by dedicated handlers on desktop, plain engine calls here
        "getDeckConfigsForUpdate", "updateDeckConfigs", "congratsInfo",
    ]

    /// Desktop dialogs, pickers, clipboard and add-on hooks that have no iOS equivalent yet.
    static let unsupported: Set<String> = [
        "openFilePicker", "recordAudio", "playFile", "readClipboard", "writeClipboard", "openMedia",
        "showInMediaFolder", "closeAddCards", "closeEditCurrent", "askUser", "showMessageBox", "openFieldsDialog",
        "openCardsDialog", "saveCustomColours", "convertPastedImage", "importDone", "importDialogRequireClose",
        "searchInBrowser", "changeNotetype", "getSchedulingStatesWithContext", "setSchedulingStates",
    ]

    private let backend: Backend
    private let events: AnkiWebEvents
    private let settings: UserDefaults

    init(backend: Backend, events: AnkiWebEvents, settings: UserDefaults = .standard) {
        self.backend = backend
        self.events = events
        self.settings = settings
    }

    func handle(_ name: String, body: Data) async -> AnkiWebResult {
        do {
            switch name {
            case "deckOptionsReady":
                await events.onReady()
                return .noContent
            case "deckOptionsRequireClose":
                await events.onClose()
                return .noContent
            case "openLink":
                let link = try Anki_Generic_String(serializedBytes: body).val
                if let url = URL(string: link), ["http", "https"].contains(url.scheme) { await events.openLink(url) }
                return .noContent
            case "getProfileConfigJson": return try getSetting("ankiweb.profile", body)
            case "setProfileConfigJson": return try setSetting("ankiweb.profile", body)
            case "getMetaJson": return try getSetting("ankiweb.meta", body)
            case "setMetaJson": return try setSetting("ankiweb.meta", body)
            case "getConfigJson":
                // A missing key is JSON null, as in mediasrv.py.
                do { return .binary(try forward(name, body)) } catch is BackendError {
                    var null = Anki_Generic_Json()
                    null.json = Data("null".utf8)
                    return .binary(try null.serializedData())
                }
            case "updateDeckConfigs":
                let request = try Anki_DeckConfig_UpdateDeckConfigsRequest(serializedBytes: body)
                let output = try forward(name, body)
                if request.mode != .computeAllParams { await events.onClose() }
                return .binary(output)
            default:
                if Self.exposed.contains(name) { return .binary(try forward(name, body)) }
                if Self.unsupported.contains(name) { return .text(501, "\(name) is not supported in Cornhub") }
                return .text(404, "\(name) not found")
            }
        } catch let error as BackendError {
            return .text(500, error.message)
        } catch {
            return .text(500, error.localizedDescription)
        }
    }

    private func forward(_ name: String, _ body: Data) throws -> Data {
        guard let index = ServiceIndex.methods[name] else {
            throw BackendError(kind: .invalidInput, message: "unknown engine method \(name)")
        }
        return try backend.callRaw(service: index.service, method: index.method, input: body)
    }

    private func getSetting(_ store: String, _ body: Data) throws -> AnkiWebResult {
        let key = try Anki_Generic_String(serializedBytes: body).val
        var json = Anki_Generic_Json()
        json.json = Data(((settings.dictionary(forKey: store) as? [String: String])?[key] ?? "null").utf8)
        return .binary(try json.serializedData())
    }

    private func setSetting(_ store: String, _ body: Data) throws -> AnkiWebResult {
        let request = try Anki_Frontend_SetSettingJsonRequest(serializedBytes: body)
        var values = settings.dictionary(forKey: store) as? [String: String] ?? [:]
        values[request.key] = String(decoding: request.valueJson, as: UTF8.self)
        settings.set(values, forKey: store)
        return .noContent
    }
}
