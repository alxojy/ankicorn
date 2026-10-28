import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Generates short text with Apple Foundation Models, or the Claude API when a Keychain key is set.
enum TextGenerator {
    static let claudeModel = "claude-sonnet-5-5"

    enum Failure: LocalizedError {
        case unavailable
        case server(String)

        var errorDescription: String? {
            switch self {
            case .unavailable:
                "No AI model is available. Apple Intelligence is off or unsupported on this device; add a Claude API key in Settings."
            case .server(let message): message
            }
        }
    }

    static var onDeviceAvailable: Bool {
        #if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability { return true }
        #endif
        return false
    }

    static var isAvailable: Bool { onDeviceAvailable || ClaudeKeychain.load() != nil }

    static func isUnsupportedLanguage(_ error: Error) -> Bool {
        #if canImport(FoundationModels)
        if let failure = error as? LanguageModelSession.GenerationError, case .unsupportedLanguageOrLocale = failure { return true }
        #endif
        return false
    }

    static func generate(instructions: String, prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        if onDeviceAvailable {
            do {
                let session = LanguageModelSession(instructions: instructions)
                return try await session.respond(to: prompt).content
            } catch {
                if ClaudeKeychain.load() == nil { throw error }
            }
        }
        #endif
        guard let key = ClaudeKeychain.load() else { throw Failure.unavailable }
        return try await claude(key: key, instructions: instructions, prompt: prompt)
    }

    private static func claude(key: String, instructions: String, prompt: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: Any] = [
            "model": claudeModel, "max_tokens": 700, "system": instructions,
            "messages": [["role": "user", "content": prompt]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let detail = (json?["error"] as? [String: Any])?["message"] as? String
            throw Failure.server(detail ?? "The Claude API request failed.")
        }
        let blocks = json?["content"] as? [[String: Any]] ?? []
        let text = blocks.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw Failure.server("The Claude API returned no text.") }
        return text
    }
}
