import AVFoundation
import Foundation

/// Per-deck speech language and the speech used for any card.
enum SpeechSettings {
    static let languages: [(code: String, name: String)] = [
        ("zh-CN", "Chinese (Mandarin)"), ("zh-TW", "Chinese (Taiwan)"), ("yue-HK", "Cantonese"),
        ("en-US", "English"), ("ja-JP", "Japanese"), ("ko-KR", "Korean"), ("es-ES", "Spanish"),
        ("fr-FR", "French"), ("de-DE", "German"),
    ]

    private static func key(_ deckID: Int64) -> String { "speechLanguage.\(deckID)" }

    static func language(deckID: Int64) -> String {
        UserDefaults.standard.string(forKey: key(deckID)) ?? "zh-CN"
    }

    static func setLanguage(_ code: String, deckID: Int64) {
        UserDefaults.standard.set(code, forKey: key(deckID))
    }
}

/// Speaks text with the system voice for a language.
@MainActor
final class Speaker {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, language: String) {
        guard !text.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = CardAudio.voice(lang: language, names: [])
        synthesizer.speak(utterance)
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }

    /// Renders speech to a CAF file, for Add card audio. Nil when the simulator or device has no voice.
    static func render(_ text: String, language: String) async -> Data? {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = CardAudio.voice(lang: language, names: [])
        let url = FileManager.default.temporaryDirectory.appending(path: "tts-\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }
        return await withCheckedContinuation { continuation in
            var file: AVAudioFile?
            var finished = false
            synthesizer.write(utterance) { buffer in
                guard !finished else { return }
                guard let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 else {
                    finished = true
                    continuation.resume(returning: file == nil ? nil : try? Data(contentsOf: url))
                    return
                }
                do {
                    if file == nil { file = try AVAudioFile(forWriting: url, settings: pcm.format.settings) }
                    try file?.write(from: pcm)
                } catch {
                    finished = true
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
