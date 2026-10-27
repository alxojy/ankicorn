import Foundation
import WebKit

/// Serves Anki's built SvelteKit pages from the app bundle and forwards `POST /_anki/<method>` to the engine.
/// URLs look like `cornhub-web://app/deck-options/1#night`; unknown paths fall back to `index.html`, which is
/// SvelteKit's single-page entry.
@MainActor
final class AnkiWebSchemeHandler: NSObject, WKURLSchemeHandler {
    nonisolated static let scheme = "cornhub-web"
    nonisolated static let apiPrefix = "/_anki/"
    /// Fonts bundled with the app (Space Grotesk), served so the Ink override can use them.
    nonisolated static let fontPrefix = "/_font/"

    private let api: AnkiWebAPI
    private var stopped = Set<ObjectIdentifier>()

    init(api: AnkiWebAPI) {
        self.api = api
    }

    /// The bundled pages (a folder reference), present only after `scripts/build-web.sh` ran.
    static var pagesFolder: URL? {
        let folder = Bundle.main.url(forResource: "AnkiWeb", withExtension: nil)
        guard let folder, FileManager.default.fileExists(atPath: folder.appending(path: "index.html").path)
        else { return nil }
        return folder
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return finish(task, .text(400, "bad request")) }
        if url.path.hasPrefix(Self.apiPrefix) {
            let name = String(url.path.dropFirst(Self.apiPrefix.count))
            let body = Self.body(of: task.request)
            let key = ObjectIdentifier(task)
            Task { [api] in
                let result = await api.handle(name, body: body)
                if stopped.remove(key) != nil { return }
                finish(task, result)
            }
        } else if url.path.hasPrefix(Self.fontPrefix) {
            finish(task, Self.font(named: String(url.path.dropFirst(Self.fontPrefix.count))))
        } else {
            finish(task, Self.page(for: url.path))
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        stopped.insert(ObjectIdentifier(task))
    }

    private func finish(_ task: WKURLSchemeTask, _ result: AnkiWebResult) {
        guard let url = task.request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: result.status, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": result.mime, "Content-Length": "\(result.body.count)"])
        else { return }
        task.didReceive(response)
        task.didReceive(result.body)
        task.didFinish()
    }

    /// WebKit hands fetch bodies to custom schemes as a stream.
    nonisolated static func body(of request: URLRequest) -> Data {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }

    /// A bundled `.ttf` by file name (no paths).
    nonisolated static func font(named name: String) -> AnkiWebResult {
        let base = (name as NSString).deletingPathExtension
        guard !name.contains("/"), (name as NSString).pathExtension == "ttf",
            let url = Bundle.main.url(forResource: base, withExtension: "ttf"), let data = try? Data(contentsOf: url)
        else { return .text(404, "no such font") }
        return AnkiWebResult(status: 200, body: data, mime: "font/ttf")
    }

    static func page(for path: String) -> AnkiWebResult {
        guard let folder = pagesFolder else { return .text(404, "The Anki web pages are not built.") }
        let relative = path.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        guard !relative.contains("..") else { return .text(400, "bad path") }
        let file = folder.appending(path: relative)
        var isDirectory: ObjCBool = false
        if !relative.isEmpty, FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
            !isDirectory.boolValue, let data = try? Data(contentsOf: file) {
            return AnkiWebResult(status: 200, body: data, mime: mimeType(file.pathExtension))
        }
        // A path with an extension that is not bundled is a real 404; anything else is a client-side route.
        if !relative.isEmpty, (relative as NSString).pathExtension != "" { return .text(404, "not found") }
        guard let index = try? Data(contentsOf: folder.appending(path: "index.html")) else { return .text(404, "no index") }
        return AnkiWebResult(status: 200, body: index, mime: "text/html")
    }

    nonisolated static func mimeType(_ ext: String) -> String {
        switch ext.lowercased() {
        case "html": "text/html"
        case "js", "mjs": "text/javascript"
        case "css": "text/css"
        case "json": "application/json"
        case "svg": "image/svg+xml"
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        case "woff2": "font/woff2"
        case "woff": "font/woff"
        case "ttf": "font/ttf"
        case "wasm": "application/wasm"
        default: "application/octet-stream"
        }
    }
}
