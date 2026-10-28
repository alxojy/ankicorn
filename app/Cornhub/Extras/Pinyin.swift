import Foundation

/// Tone-marked pinyin from hanzi, computed on the device with the system transliterator.
enum Pinyin {
    /// Pinyin for the hanzi in `html` (markup stripped), lower case; empty when there is no hanzi.
    static func from(_ html: String) -> String {
        let text = CardText.plain(html).replacingOccurrences(of: "\n", with: " ")
        guard !CardText.hanzi(text).isEmpty else { return "" }
        let latin = text.applyingTransform(.mandarinToLatin, reverse: false) ?? ""
        return latin.lowercased().split(separator: " ").joined(separator: " ")
    }
}
