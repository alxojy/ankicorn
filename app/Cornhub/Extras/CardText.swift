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
