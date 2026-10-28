import Foundation

/// Plain text and hanzi pulled out of rendered card HTML.
enum CardText {
    static func plain(_ html: String) -> String {
        var text = html.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "<br\\s*/?>|</div>|</p>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        for (entity, value) in [("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'")] {
            text = text.replacingOccurrences(of: entity, with: value)
        }
        return text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }.joined(separator: "\n")
    }

    /// Distinct CJK ideographs in order of appearance.
    static func hanzi(_ text: String) -> [Character] {
        var seen = Set<Character>()
        return text.filter { $0.unicodeScalars.first.map { (0x4E00...0x9FFF).contains($0.value) } ?? false }
            .filter { seen.insert($0).inserted }
    }
}

/// What the Speak action says: the note's own audio, or just the headword.
enum SpeechTarget: Equatable {
    case audio(String)
    case text(String)

    private static let soundPattern = try? NSRegularExpression(pattern: "\\[sound:([^\\]]+)\\]")
    private static let headwordNames = ["hanzi", "simplified", "traditional", "word", "front", "expression"]

    /// `names` and `fields` are the note's field names and values; `question` is the rendered question HTML.
    static func pick(names: [String], fields: [String], question: String, language: String) -> SpeechTarget {
        for value in fields + [question] {
            let range = NSRange(value.startIndex..., in: value)
            if let match = soundPattern?.firstMatch(in: value, range: range),
                let file = Range(match.range(at: 1), in: value) {
                return .audio(String(value[file]))
            }
        }
        let named = names.firstIndex { headwordNames.contains($0.lowercased()) }
        let raw = named.flatMap { fields.indices.contains($0) ? fields[$0] : nil } ?? fields.first ?? question
        var text = CardText.plain(raw)
        if text.isEmpty { text = CardText.plain(question) }
        text = text.replacingOccurrences(of: "\\[[^\\]]*\\]", with: "", options: .regularExpression)
        if language.hasPrefix("zh") {
            let hanzi = text.filter { $0.unicodeScalars.first.map { (0x4E00...0x9FFF).contains($0.value) } ?? false }
            if !hanzi.isEmpty { text = String(hanzi) }
        }
        return .text(text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces))
    }
}
