import Foundation

/// Converts a note field's HTML to styled text and back. Only the formatting the editor can show is
/// converted; a field with any other markup returns `nil` and is edited as plain-text HTML instead,
/// so nothing is ever dropped.
enum FieldHTML {
    private static let entities: [String: String] = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&nbsp;": "\u{00A0}"]

    /// Parses `html` into styled text, or returns nil when it holds markup the editor can't display.
    static func attributed(from html: String) -> AttributedString? {
        var result = AttributedString()
        var bold = 0, italic = 0, underline = 0
        var buffer = ""

        func flush() {
            guard !buffer.isEmpty else { return }
            var run = AttributedString(buffer)
            var intent: InlinePresentationIntent = []
            if bold > 0 { intent.insert(.stronglyEmphasized) }
            if italic > 0 { intent.insert(.emphasized) }
            if !intent.isEmpty { run.inlinePresentationIntent = intent }
            if underline > 0 { run.underlineStyle = .single }
            result += run
            buffer = ""
        }

        var index = html.startIndex
        while index < html.endIndex {
            let char = html[index]
            if char == "<" {
                guard let close = html[index...].firstIndex(of: ">") else { return nil }
                let tag = html[html.index(after: index)..<close].lowercased().trimmingCharacters(in: .whitespaces)
                flush()
                switch tag {
                case "b", "strong": bold += 1
                case "/b", "/strong": bold -= 1
                case "i", "em": italic += 1
                case "/i", "/em": italic -= 1
                case "u": underline += 1
                case "/u": underline -= 1
                case "br", "br/", "br /": buffer = "\n"; flush()
                default: return nil
                }
                if bold < 0 || italic < 0 || underline < 0 { return nil }
                index = html.index(after: close)
            } else if char == "&" {
                guard let semi = html[index...].firstIndex(of: ";"),
                    let value = entities[String(html[index...semi]).lowercased()]
                else { return nil }
                buffer += value
                index = html.index(after: semi)
            } else if char == "\n" || char == "\r" {
                return nil
            } else {
                buffer.append(char)
                index = html.index(after: index)
            }
        }
        flush()
        guard bold == 0, italic == 0, underline == 0 else { return nil }
        return result
    }

    /// Serialises styled text to field HTML, wrapping bold, italic and underlined runs in `<b>`, `<i>` and `<u>`.
    static func html(from text: AttributedString) -> String {
        var out = ""
        for run in text.runs {
            let intent = run.inlinePresentationIntent ?? []
            let isBold = intent.contains(.stronglyEmphasized), isItalic = intent.contains(.emphasized)
            let isUnderlined = run.underlineStyle != nil
            var chunk = ""
            for char in String(text[run.range].characters) {
                switch char {
                case "&": chunk += "&amp;"
                case "<": chunk += "&lt;"
                case ">": chunk += "&gt;"
                case "\u{00A0}": chunk += "&nbsp;"
                case "\n": chunk += "<br>"
                default: chunk.append(char)
                }
            }
            if isUnderlined { chunk = "<u>\(chunk)</u>" }
            if isItalic { chunk = "<i>\(chunk)</i>" }
            if isBold { chunk = "<b>\(chunk)</b>" }
            out += chunk
        }
        return out
    }
}
