import Foundation

/// The bundled "Chinese vocab (2-way)" note type from PLAN.md: picture, hanzi with pinyin and audio, English
/// meaning, then the example sentence. Built on the stock Basic note type's JSON so every legacy key is present.
enum ChineseNotetype {
    static let name = "Chinese vocab (2-way)"
    static let fields = ["Hanzi", "Pinyin", "English", "Picture", "Example", "Example pinyin", "Example English", "Audio"]

    /// Field indices, matching `fields`.
    enum Field {
        static let hanzi = 0, pinyin = 1, english = 2, picture = 3, example = 4
        static let examplePinyin = 5, exampleEnglish = 6, audio = 7
    }

    private static let answer = """
        {{#Picture}}<div class="pic">{{Picture}}</div>{{/Picture}}
        <div class="head"><span class="hanzi">{{Hanzi}}</span><span class="pinyin">{{Pinyin}}</span></div>
        {{Audio}}
        <hr class="rule">
        <div class="english">{{English}}</div>
        {{#Example}}<div class="example">{{Example}}</div>
        <div class="muted">{{Example pinyin}}</div><div class="muted">{{Example English}}</div>{{/Example}}
        """

    /// (name, question, answer) for the two cards. The answer replaces the question, so no FrontSide.
    static let templates: [(String, String, String)] = [
        ("Hanzi to English", "<div class=\"big hanzi\">{{Hanzi}}</div>", answer),
        ("English to Hanzi", "<div class=\"big english\">{{English}}</div>", answer)
    ]

    /// Card styling in the Ink look; colours come from the theme tokens (resolved for dark mode).
    static var css: String {
        let text = CardWebView.hex(Theme.text), muted = CardWebView.hex(Theme.muted)
        let accent = CardWebView.hex(Theme.accent), text2 = CardWebView.hex(Theme.text2)
        return """
        .card { font-family: -apple-system, "PingFang SC", sans-serif; font-size: 20px; text-align: center; color: \(text); }
        .big { font-size: 28px; } .big.hanzi { font-size: 60px; }
        .pic img { max-height: 130px; border-radius: 20px; margin-bottom: 12px; }
        .head { display: flex; align-items: baseline; justify-content: center; gap: 12px; }
        .hanzi { font-size: 60px; line-height: 1.1; }
        .pinyin { color: \(accent); font-size: 22px; }
        hr.rule { border: 0; border-top: 1px solid \(muted); opacity: 0.4; margin: 16px 0; }
        .english { font-size: 28px; font-weight: 600; margin-bottom: 14px; }
        .example { font-size: 20px; color: \(text2); } .example b { color: \(accent); }
        .muted { color: \(muted); font-size: 16px; margin-top: 4px; }
        """
    }

    /// Legacy JSON for the note type, from the stock Basic JSON.
    static func json(basedOn stock: Data) throws -> Data {
        guard var model = try JSONSerialization.jsonObject(with: stock) as? [String: Any],
            let field = (model["flds"] as? [[String: Any]])?.first,
            let template = (model["tmpls"] as? [[String: Any]])?.first
        else { throw BackendError(kind: .invalidInput, message: "unexpected stock note type") }
        model["id"] = 0
        model["name"] = name
        model["css"] = css
        model["flds"] = fields.enumerated().map { index, fieldName in
            var copy = field
            copy["name"] = fieldName
            copy["ord"] = index
            return copy
        }
        model["tmpls"] = templates.enumerated().map { index, spec in
            var copy = template
            copy["name"] = spec.0
            copy["qfmt"] = spec.1
            copy["afmt"] = spec.2
            copy["ord"] = index
            return copy
        }
        return try JSONSerialization.data(withJSONObject: model)
    }
}

extension Backend {
    /// The id of the Chinese vocab note type, adding it on first launch when missing.
    @discardableResult
    func ensureChineseNotetype() throws -> Int64 {
        if let existing = try notetypeNames().first(where: { $0.name == ChineseNotetype.name }) { return existing.id }
        return try addNotetype(json: try ChineseNotetype.json(basedOn: try stockNotetypeJSON(kind: .basic)))
    }
}
