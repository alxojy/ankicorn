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

/// What the Speak action says: the note's own audio (with the headword to say if the file is missing), or just the headword.
enum SpeechTarget: Equatable {
    case audio(String, fallback: String)
    case text(String)

    private static let soundPattern = try? NSRegularExpression(pattern: "\\[sound:([^\\]]+)\\]")
    private static let headwordNames = ["hanzi", "simplified", "traditional", "word", "front", "expression"]

    /// `names` and `fields` are the note's field names and values; `question` is the rendered question HTML.
    static func pick(names: [String], fields: [String], question: String, language: String) -> SpeechTarget {
        let word = headword(names: names, fields: fields, question: question, language: language)
        for value in fields + [question] {
            let range = NSRange(value.startIndex..., in: value)
            if let match = soundPattern?.firstMatch(in: value, range: range),
                let file = Range(match.range(at: 1), in: value) {
                return .audio(String(value[file]), fallback: word)
            }
        }
        return .text(word)
    }

    /// The main word of any note type: a field named like a headword, else the first field that is mostly hanzi,
    /// else the first field with text, else the question. HTML, sound tags and cloze markup are stripped.
    static func headword(names: [String], fields: [String], question: String, language: String) -> String {
        let cleaned = fields.map(clean)
        let named = names.indices.first {
            headwordNames.contains(names[$0].lowercased()) && cleaned.indices.contains($0) && !cleaned[$0].isEmpty
        }
        let index = named
            ?? cleaned.firstIndex { mostlyHanzi($0) }
            ?? cleaned.firstIndex { !$0.isEmpty }
        var text = index.map { cleaned[$0] } ?? clean(question)
        if text.isEmpty { text = clean(question) }
        if language.hasPrefix("zh") {
            let hanzi = text.filter { isHanzi($0) }
            if !hanzi.isEmpty { text = hanzi }
        }
        return text
    }

    static func isHanzi(_ character: Character) -> Bool {
        character.unicodeScalars.first.map { (0x4E00...0x9FFF).contains($0.value) } ?? false
    }

    /// At least half of the letters are hanzi.
    static func mostlyHanzi(_ text: String) -> Bool {
        let letters = text.filter { $0.isLetter }
        return !letters.isEmpty && letters.filter { isHanzi($0) }.count * 2 >= letters.count
    }

    /// Plain single-line text: no HTML, `[sound:]` or other bracket tags, and cloze answers kept without hints.
    static func clean(_ html: String) -> String {
        var text = CardText.plain(html)
        text = text.replacingOccurrences(
            of: "\\{\\{c\\d+::(.*?)(?:::[^}]*)?\\}\\}", with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\[[^\\]]*\\]", with: "", options: .regularExpression)
        return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
