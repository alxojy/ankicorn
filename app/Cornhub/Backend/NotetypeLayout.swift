import Foundation

/// Rewrites a note type's card templates and CSS into the Cornhub review layout (PLAN.md › Review) using the note
/// type's own fields. Only builds strings: storage, undo and sync are the engine's. The old templates are kept in
/// an HTML comment inside each template and the old CSS in the `NotetypeStyle` comment block, so they can be put
/// back exactly.
enum NotetypeLayout {
    /// What a field is for on the card.
    enum Role: String, CaseIterable, Identifiable {
        case hanzi, pinyin, meaning, partOfSpeech, picture, example, examplePinyin, exampleMeaning, extra

        var id: String { rawValue }

        var title: String {
            switch self {
            case .hanzi: "Hanzi"
            case .pinyin: "Pinyin"
            case .meaning: "Meaning"
            case .partOfSpeech: "Part of speech"
            case .picture: "Picture"
            case .example: "Example"
            case .examplePinyin: "Example pinyin"
            case .exampleMeaning: "Example meaning"
            case .extra: "Extra"
            }
        }
    }

    /// Which field plays which role. `audio` may hold several fields (word and sentence audio).
    struct Mapping: Equatable {
        var fields: [Role: String] = [:]
        var audio: [String] = []
        var showExampleOnFront = false

        subscript(role: Role) -> String? {
            get { fields[role] }
            set { fields[role] = newValue }
        }

        /// Fields without any role: they are not shown on the card.
        func unmapped(in names: [String]) -> [String] {
            let used = Set(fields.values).union(audio)
            return names.filter { !used.contains($0) }
        }
    }

    static let frontMarker = "<!-- cornhub: previous front"
    static let backMarker = "<!-- cornhub: previous back"

    // MARK: Guessing

    /// Names that mark a note type as having a hanzi-like field.
    private static let hanziWords = ["hanzi", "simplified", "traditional", "chinese", "character", "汉字", "漢字"]

    /// Whether the layout is offered for a note type with these field names.
    static func offered(for fieldNames: [String]) -> Bool {
        fieldNames.contains { name in hanziWords.contains { name.lowercased().contains($0) } }
    }

    /// Guesses each role from the field names, falling back to the field the front template shows first.
    static func guess(fields names: [String], frontTemplate: String = "") -> Mapping {
        var mapping = Mapping()
        var free = names
        func lower(_ name: String) -> String { name.lowercased() }
        func has(_ name: String, _ words: [String]) -> Bool { words.contains { lower(name).contains($0) } }
        func isSentence(_ name: String) -> Bool { has(name, ["sentence", "example"]) }
        func take(_ role: Role, _ matches: (String) -> Bool) {
            guard let found = free.first(where: matches) else { return }
            mapping[role] = found
            free.removeAll { $0 == found }
        }
        for name in names where has(name, ["audio", "sound"]) {
            mapping.audio.append(name)
            free.removeAll { $0 == name }
        }
        take(.picture) { has($0, ["image", "picture", "img", "photo"]) }
        take(.examplePinyin) { isSentence($0) && has($0, ["pinyin", "reading"]) }
        take(.exampleMeaning) { isSentence($0) && has($0, ["meaning", "english", "transl"]) }
        take(.example) { isSentence($0) }
        take(.pinyin) { has($0, ["pinyin", "reading", "pron"]) }
        take(.meaning) { has($0, ["meaning", "english", "transl", "definition", "gloss"]) }
        take(.partOfSpeech) { has($0, ["part of speech", "pos", "wordclass"]) }
        take(.hanzi) { has($0, ["simplified", "hanzi", "headword", "character", "汉字"]) }
        if mapping[.hanzi] == nil {
            take(.hanzi) { has($0, ["traditional", "chinese", "word", "expression"]) }
        }
        if mapping[.hanzi] == nil, let shown = referencedFields(in: frontTemplate).first(where: free.contains) {
            mapping[.hanzi] = shown
            free.removeAll { $0 == shown }
        }
        take(.extra) { has($0, ["homograph", "extra", "note"]) }
        return mapping
    }

    /// Field names a template mentions, in order (`{{Field}}`, `{{#Field}}`, `{{filter:Field}}`).
    static func referencedFields(in template: String) -> [String] {
        let pattern = try? NSRegularExpression(pattern: #"\{\{[#^/]?([^{}]+)\}\}"#)
        let range = NSRange(template.startIndex..., in: template)
        var seen: [String] = []
        for match in pattern?.matches(in: template, range: range) ?? [] {
            guard let whole = Range(match.range(at: 1), in: template) else { continue }
            let name = String(template[whole]).split(separator: ":").last.map(String.init) ?? ""
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty, trimmed != "FrontSide", !seen.contains(trimmed) { seen.append(trimmed) }
        }
        return seen
    }

    // MARK: Templates

    /// The question template: the hanzi (and Extra) centred; the example only when asked for.
    static func front(_ mapping: Mapping) -> String {
        var html = "<div class=\"cl-card\">\n"
        if let hanzi = mapping[.hanzi] { html += "<div class=\"cl-hanzi cl-solo\">{{\(hanzi)}}</div>\n" }
        if let extra = mapping[.extra] { html += optional(extra, "<div class=\"cl-muted\">{{\(extra)}}</div>") + "\n" }
        if mapping.showExampleOnFront, let example = mapping[.example] {
            html += optional(example, "<div class=\"cl-example\">{{\(example)}}</div>") + "\n"
        }
        return html + "</div>"
    }

    /// The answer template: picture, hanzi with pinyin, hairline, meaning, example. Audio tags are kept.
    static func back(_ mapping: Mapping) -> String {
        var html = "<div class=\"cl-card\">\n"
        if let picture = mapping[.picture] { html += optional(picture, "<div class=\"cl-pic\">{{\(picture)}}</div>") + "\n" }
        html += "<div class=\"cl-head\">\n"
        if let hanzi = mapping[.hanzi] { html += "<span class=\"cl-hanzi\">{{\(hanzi)}}</span>\n" }
        if let pinyin = mapping[.pinyin] { html += "<span class=\"cl-pinyin\">{{\(pinyin)}}</span>\n" }
        html += "</div>\n"
        if let extra = mapping[.extra] { html += optional(extra, "<div class=\"cl-muted\">{{\(extra)}}</div>") + "\n" }
        for audio in mapping.audio { html += "{{\(audio)}}\n" }
        html += "<hr id=\"answer\" class=\"cl-rule\">\n"
        if let meaning = mapping[.meaning] { html += "<div class=\"cl-meaning\">{{\(meaning)}}</div>\n" }
        if let part = mapping[.partOfSpeech] { html += optional(part, "<div class=\"cl-muted\">{{\(part)}}</div>") + "\n" }
        if let example = mapping[.example] {
            html += optional(example, "<div class=\"cl-example\">{{\(example)}}</div>") + "\n"
        }
        if let pinyin = mapping[.examplePinyin] { html += optional(pinyin, "<div class=\"cl-muted\">{{\(pinyin)}}</div>") + "\n" }
        if let meaning = mapping[.exampleMeaning] {
            html += optional(meaning, "<div class=\"cl-muted\">{{\(meaning)}}</div>") + "\n"
        }
        return html + "</div>"
    }

    private static func optional(_ field: String, _ body: String) -> String { "{{#\(field)}}\(body){{/\(field)}}" }

    /// `template` in the Cornhub layout with its previous text kept in a trailing comment. A template that is
    /// already converted is converted again from its original.
    static func wrap(_ new: String, original: String, marker: String) -> String {
        new + "\n" + marker + "\n" + escape(original) + "\n-->"
    }

    /// The text a converted template had before, if it carries the comment.
    static func previous(in template: String, marker: String) -> String? {
        guard let start = template.range(of: marker + "\n"), let end = template.range(of: "\n-->", options: .backwards),
            start.upperBound <= end.lowerBound
        else { return nil }
        return unescape(String(template[start.upperBound..<end.lowerBound]))
    }

    /// Field tags and comment terminators are neutralised so the engine does not parse the kept copy.
    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "{{", with: "&#123;&#123;").replacingOccurrences(of: "}}", with: "&#125;&#125;")
            .replacingOccurrences(of: "-->", with: "--&gt;")
    }

    private static func unescape(_ text: String) -> String {
        text.replacingOccurrences(of: "--&gt;", with: "-->").replacingOccurrences(of: "&#125;&#125;", with: "}}")
            .replacingOccurrences(of: "&#123;&#123;", with: "{{")
    }

    // MARK: CSS

    /// The layout CSS wrapped around the original CSS (kept in the `NotetypeStyle` comment block).
    static func css(original css: String) -> String {
        let original = NotetypeStyle.previous(in: css) ?? css
        let text = CardWebView.hex(Theme.text), muted = CardWebView.hex(Theme.muted)
        let accent = CardWebView.hex(Theme.accent)
        let (lightText, lightMuted, lightAccent) = (NotetypeStyle.lightText, NotetypeStyle.lightMuted, NotetypeStyle.lightAccent)
        func colour(_ selector: String, _ light: String, _ dark: String, _ declarations: String = "") -> String {
            "\(selector) { \(declarations) color: \(light); }\n.nightMode \(selector), .night_mode \(selector) { color: \(dark); }\n"
        }
        var out = """
            .card { font-family: -apple-system, "PingFang SC", sans-serif; font-size: 20px; text-align: center; color: \(lightText); }
            .nightMode .card, .night_mode .card { color: \(text); }
            .cl-pic img { max-width: 100%; max-height: 130px; border-radius: 20px; margin-bottom: 12px; }
            .cl-head { display: flex; align-items: baseline; justify-content: center; flex-wrap: wrap; gap: 4px 12px; }
            .cl-solo { text-align: center; }
            hr.cl-rule { border: 0; border-top: 1px solid \(lightMuted); opacity: 0.4; margin: 16px 0; }
            .nightMode hr.cl-rule, .night_mode hr.cl-rule { border-top-color: \(muted); }
            .cl-example b { color: \(lightAccent); }
            .nightMode .cl-example b, .night_mode .cl-example b { color: \(accent); }

            """
        out += colour(".cl-hanzi", lightText, text, "font-size: 60px; line-height: 1.15;")
        out += colour(".cl-pinyin", lightAccent, accent, "font-size: 22px;")
        out += colour(
            ".cl-meaning", lightText, text,
            "font-family: \"Space Grotesk\", -apple-system, sans-serif; font-size: 28px; font-weight: 600; margin-bottom: 6px;")
        out += colour(".cl-example", lightText, text, "font-size: 22px; margin: 14px 0 6px;")
        out += colour(".cl-muted", lightMuted, muted, "font-size: 16px; margin-top: 4px;")
        out += "\n" + NotetypeStyle.marker + "\n" + original.replacingOccurrences(of: "*/", with: "*\\/") + "\n*/\n"
        return out
    }

    // MARK: Whole note type

    /// Whether any template or the CSS still carries the original layout.
    static func canRestore(_ notetype: Anki_Notetypes_Notetype) -> Bool {
        NotetypeStyle.canRestore(css: notetype.config.css)
            && notetype.templates.contains { previous(in: $0.config.qFormat, marker: frontMarker) != nil }
    }

    /// `notetype` with every template and the CSS in the Cornhub layout. Fields, template names and ordinals are
    /// untouched, so the engine has nothing to reconcile in the notes.
    static func applying(_ mapping: Mapping, to notetype: Anki_Notetypes_Notetype) -> Anki_Notetypes_Notetype {
        var edited = notetype
        for index in edited.templates.indices {
            let config = edited.templates[index].config
            let oldFront = previous(in: config.qFormat, marker: frontMarker) ?? config.qFormat
            let oldBack = previous(in: config.aFormat, marker: backMarker) ?? config.aFormat
            edited.templates[index].config.qFormat = wrap(front(mapping), original: oldFront, marker: frontMarker)
            edited.templates[index].config.aFormat = wrap(back(mapping), original: oldBack, marker: backMarker)
        }
        edited.config.css = css(original: notetype.config.css)
        return edited
    }

    /// `notetype` with the original templates and CSS back exactly, or nil when there is nothing to restore.
    static func restoring(_ notetype: Anki_Notetypes_Notetype) -> Anki_Notetypes_Notetype? {
        guard canRestore(notetype), let css = NotetypeStyle.restored(from: notetype.config.css) else { return nil }
        var edited = notetype
        for index in edited.templates.indices {
            let config = edited.templates[index].config
            if let front = previous(in: config.qFormat, marker: frontMarker) {
                edited.templates[index].config.qFormat = front
            }
            if let back = previous(in: config.aFormat, marker: backMarker) {
                edited.templates[index].config.aFormat = back
            }
        }
        edited.config.css = css
        return edited
    }

    /// The templates before conversion (for guessing roles from a note type that is already converted).
    static func originalFront(_ notetype: Anki_Notetypes_Notetype) -> String {
        guard let first = notetype.templates.first else { return "" }
        return previous(in: first.config.qFormat, marker: frontMarker) ?? first.config.qFormat
    }
}
