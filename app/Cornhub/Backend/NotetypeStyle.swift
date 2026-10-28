import Foundation

/// Rewrites a note type's CSS into the Cornhub (Ink) look. Class names are kept so templates stay untouched; the
/// old CSS is kept in a comment block at the end so it can be restored. Only builds a string: storage, undo and
/// sync are the engine's.
enum NotetypeStyle {
    static let marker = "/* cornhub: previous css"

    /// What a class is for, guessed from its name (and, for the headword, its size).
    enum Role: Equatable {
        case headword, pinyin, meaning, sentence, description
    }

    /// True when `css` still carries the original style of a restyled note type.
    static func canRestore(css: String) -> Bool { previous(in: css) != nil }

    /// Whether the note type sets its own opaque `.card` background, so the review menu offers a restyle.
    static func setsOwnBackground(css: String) -> Bool { CardStyle.decide(css: css) != .ink }

    /// The Ink CSS for a note type whose CSS is `css`. Restyling an already restyled note type starts again from
    /// the original, so generating twice gives the same result.
    static func generate(from css: String) -> String {
        let original = previous(in: css) ?? css
        let text = CardWebView.hex(Theme.text), muted = CardWebView.hex(Theme.muted)
        let accent = CardWebView.hex(Theme.accent)
        var out = """
            .card { font-family: -apple-system, "PingFang SC", sans-serif; font-size: 20px; text-align: center; color: \(lightText); }
            .nightMode .card, .night_mode .card { color: \(text); }
            img { max-width: 100%; max-height: \(CardWebView.imageMaxHeight)px; border-radius: 20px; }

            """
        for (name, role) in classes(in: original) {
            out += rules(for: name, role: role, night: (text, muted, accent))
        }
        out += "\n" + marker + "\n" + original.replacingOccurrences(of: "*/", with: "*\\/") + "\n*/\n"
        return out
    }

    /// The CSS the note type had before it was restyled, if the comment block is present.
    static func previous(in css: String) -> String? {
        guard let start = css.range(of: marker + "\n"), let end = css.range(of: "\n*/", options: .backwards),
            start.upperBound <= end.lowerBound
        else { return nil }
        return String(css[start.upperBound..<end.lowerBound]).replacingOccurrences(of: "*\\/", with: "*/")
    }

    /// The CSS to save to restore the original style, or nil when there is nothing to restore.
    static func restored(from css: String) -> String? { previous(in: css) }

    // MARK: Mapping

    private static let lightText = "#1C1C1E", lightMuted = "#5F5F66", lightAccent = "#0B6B52"

    /// Simple `.class` selectors of `css` (in first-seen order) with their role.
    static func classes(in css: String) -> [(String, Role)] {
        var sizes: [String: Double] = [:], order: [String] = []
        let stripped = CardStyle.strippingComments(css)
        let whole = NSRange(stripped.startIndex..., in: stripped)
        let blocks = try? NSRegularExpression(pattern: #"([^{}]+)\{([^}]*)\}"#)
        let size = try? NSRegularExpression(pattern: #"(?<![\w-])font-size\s*:\s*([\d.]+)\s*px"#)
        for block in blocks?.matches(in: stripped, range: whole) ?? [] {
            guard let selectorRange = Range(block.range(at: 1), in: stripped),
                let bodyRange = Range(block.range(at: 2), in: stripped)
            else { continue }
            let body = String(stripped[bodyRange])
            let pixels = size?.firstMatch(in: body, range: NSRange(body.startIndex..., in: body))
                .flatMap { Range($0.range(at: 1), in: body) }.flatMap { Double(body[$0]) }
            for part in stripped[selectorRange].split(separator: ",") {
                let name = part.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.range(of: #"^\.[A-Za-z_][\w-]*$"#, options: .regularExpression) != nil, name != ".card"
                else { continue }
                if !order.contains(name) { order.append(name) }
                if let pixels { sizes[name] = max(sizes[name] ?? 0, pixels) }
            }
        }
        var roles = order.map { ($0, role(named: $0)) }
        let named = roles.contains { $0.1 == .headword }
        if !named, let biggest = sizes.filter({ $0.value >= 40 }).max(by: { $0.value < $1.value })?.key,
            let index = roles.firstIndex(where: { $0.0 == biggest }), roles[index].1 == nil {
            roles[index].1 = .headword
        }
        return roles.compactMap { name, role in role.map { (name, $0) } }
    }

    private static func role(named name: String) -> Role? {
        let lower = name.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { lower.contains($0) } }
        if has(["pinyin", "reading", "pron", "phonetic", "kana"]) { return .pinyin }
        if has(["desc", "note", "hint", "pos", "part", "tag"]) { return .description }
        if has(["english", "meaning", "transl", "gloss", "defin"]) { return .meaning }
        if has(["sent", "example", "phrase"]) { return .sentence }
        if has(["hanzi", "headword", "word", "char", "simplified", "traditional", "expression", "kanji", "front"]) {
            return .headword
        }
        return nil
    }

    private static func rules(for name: String, role: Role, night: (String, String, String)) -> String {
        let (text, muted, accent) = night
        func block(_ declarations: String, light: String, dark: String) -> String {
            "\(name) { \(declarations) color: \(light); }\n.nightMode \(name), .night_mode \(name) { color: \(dark); }\n"
        }
        switch role {
        case .headword:
            return block("font-size: 56px; line-height: 1.15; text-align: center;", light: lightText, dark: text)
        case .pinyin:
            return block("font-size: 20px;", light: lightAccent, dark: accent)
        case .meaning:
            return block("font-size: 20px; font-weight: 600;", light: lightText, dark: text)
        case .sentence:
            return block("font-size: 24px;", light: lightText, dark: text)
        case .description:
            return block("font-size: 16px;", light: lightMuted, dark: muted)
        }
    }
}
