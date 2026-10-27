import CryptoKit
import Foundation

/// Explanations saved per note, keyed by note ID and a hash of the card text so edits invalidate them.
struct ExplanationCache {
    private let url: URL

    init(url: URL = ExplanationCache.defaultURL) { self.url = url }

    static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appending(path: "explanations.json")
    }

    static func key(noteID: Int64, text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8)).prefix(6).map { String(format: "%02x", $0) }.joined()
        return "\(noteID)-\(digest)"
    }

    func value(for key: String) -> String? { load()[key] }

    func store(_ value: String, for key: String) {
        var all = load()
        all[key] = value
        if let data = try? JSONEncoder().encode(all) { try? data.write(to: url, options: .atomic) }
    }

    private func load() -> [String: String] {
        guard let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
}
