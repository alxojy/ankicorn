import AVFoundation
import Foundation

/// Plays a side's sounds and TTS tags one after another.
@MainActor
final class CardAudio: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var queue: [AVItem] = []

    func play(_ items: [AVItem]) {
        stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        queue = items
        next()
    }

    func stop() {
        queue = []
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func next() {
        guard !queue.isEmpty else { return }
        switch queue.removeFirst() {
        case .file(let name):
            let url = MediaSchemeHandler.mediaFolder.appending(path: name)
            guard let audio = try? AVAudioPlayer(contentsOf: url) else { return next() }
            audio.delegate = self
            player = audio
            audio.play()
        case .tts(let text, let lang, let voices, let speed):
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = Self.voice(lang: lang, names: voices)
            if speed > 0 { utterance.rate = min(AVSpeechUtteranceMaximumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * speed) }
            synthesizer.speak(utterance)
            // Speech runs on the synthesizer's own queue; remaining items follow once it ends.
            Task { [weak self] in
                while self?.synthesizer.isSpeaking == true { try? await Task.sleep(for: .milliseconds(100)) }
                self?.next()
            }
        }
    }

    /// A system voice matching the tag's language, preferring a name the tag lists.
    static func voice(lang: String, names: [String]) -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let code = lang.replacingOccurrences(of: "_", with: "-")
        if let named = all.first(where: { voice in
            names.contains { voice.name.localizedCaseInsensitiveContains($0) } && voice.language.hasPrefix(code.prefix(2))
        }) { return named }
        return AVSpeechSynthesisVoice(language: code) ?? all.first { $0.language.hasPrefix(code.prefix(2)) }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.next() }
    }
}
