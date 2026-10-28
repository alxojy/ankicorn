import Foundation
import WebKit

/// Serves `cornhub://media/<file>` from collection.media and `cornhub://app/<file>` from the app bundle.
final class MediaSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "cornhub"
    static let mediaFolder = URL.documentsDirectory.appending(path: "collection.media")

    static func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: mediaFolder.appending(path: name).path)
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, let file = Self.fileURL(for: url),
            let data = try? Data(contentsOf: file)
        else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let mime = Self.mimeType(file.pathExtension)
        let response = URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    static func fileURL(for url: URL) -> URL? {
        let name = url.path.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        guard !name.isEmpty, !name.contains("..") else { return nil }
        switch url.host {
        case "media": return mediaFolder.appending(path: name)
        case "app": return Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Web")
                ?? Bundle.main.url(forResource: name, withExtension: nil)
        default: return nil
        }
    }

    static func mimeType(_ ext: String) -> String {
        switch ext.lowercased() {
        case "js": "text/javascript"
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        case "gif": "image/gif"
        case "svg": "image/svg+xml"
        case "webp": "image/webp"
        case "mp3": "audio/mpeg"
        case "m4a": "audio/mp4"
        case "wav": "audio/wav"
        case "css": "text/css"
        default: "application/octet-stream"
        }
    }
}
