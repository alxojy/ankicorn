import UIKit

/// Invented note types shaped like common shared decks, for the compatibility tests and screenshots. Nothing
/// here comes from a real deck.
enum ImportedFixtures {
    static let lightName = "Shared deck style"
    static let darkName = "Dark deck style"
    static let imageFile = "fx-moon.jpg"
    static let soundFile = "fx-moon.mp3"
    static let sentenceSoundFile = "fx-moon-sentence.mp3"

    /// Dotted field names and media fields, as in many shared decks.
    static let fields = [
        "Key", "Simplified", "Pinyin.1", "Pinyin.2", "Meaning", "Part of speech", "Audio", "SentenceSimplified",
        "SentencePinyin.1", "SentenceMeaning", "SentenceAudio", "SentenceImage"
    ]

    /// Light `.card` background and, like the real shape, a declaration that lost its `color:` property.
    static let lightCSS = """
        .card {font-family: arial; font-size: 14px; text-align: left; #222222; background-color: #fdf6e3;}
        .hanzi {font-family: Kaiti; font-size: 64px;}
        .pinyin {font-family: Gentium Plus; font-size: 22px; color: #005500;}
        .english, .meaningSent, .description {font-family: Georgia; font-size: 16px;}
        .description {color: #575757;}
        .sentence {font-family: SimSun; font-size: 24px;}
        """

    static let darkCSS = """
        .card {font-family: arial; font-size: 16px; text-align: center; color: #eeeeee; background-color: #1b2a3a;}
        .hanzi {font-size: 64px;}
        .pinyin {color: #7fd1ae; font-size: 22px;}
        img {width: 100%; height: 600px;}
        """

    static let front = "<div class=\"hanzi\">{{Simplified}}</div><div class=\"pinyin\">{{Pinyin.1}}</div>{{Audio}}"

    /// No `{{FrontSide}}`: the answer lays out everything itself.
    static let back = """
        <div class="hanzi">{{Simplified}}</div><div class="pinyin">{{Pinyin.1}} {{Pinyin.2}}</div>
        <div class="english">{{Meaning}}</div><div class="description">{{Part of speech}}</div>
        <hr><div class="sentence">{{SentenceSimplified}}</div><div class="pinyin">{{SentencePinyin.1}}</div>
        <div class="meaningSent">{{SentenceMeaning}}</div>{{SentenceImage}}{{SentenceAudio}}
        """

    /// (word, pinyin, meaning, sentence, sentence pinyin, sentence meaning).
    static let lightNote = ["月亮", "yuèliang", "moon", "今晚的<b>月亮</b>很圆。", "Jīnwǎn de yuèliang hěn yuán.", "The moon is round tonight."]
    static let darkNote = ["星星", "xīngxing", "star", "天上有很多<b>星星</b>。", "Tiānshàng yǒu hěn duō xīngxing.", "There are many stars in the sky."]

    static func fieldValues(_ note: [String], withMedia: Bool) -> [String] {
        [
            note[0], note[0], note[1], "", note[2], "noun", withMedia ? "[sound:\(soundFile)]" : "",
            note[3], note[4], note[5], withMedia ? "[sound:\(sentenceSoundFile)]" : "",
            withMedia ? "<img src=\"\(imageFile)\">" : ""
        ]
    }

    static func json(basedOn stock: Data, name: String, css: String) throws -> Data {
        guard var model = try JSONSerialization.jsonObject(with: stock) as? [String: Any],
            let field = (model["flds"] as? [[String: Any]])?.first,
            var template = (model["tmpls"] as? [[String: Any]])?.first
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
        template["name"] = "Recognition"
        template["qfmt"] = front
        template["afmt"] = back
        template["ord"] = 0
        model["tmpls"] = [template]
        return try JSONSerialization.data(withJSONObject: model)
    }

    /// A small solid-colour jpg, generated here.
    static func jpegData() -> Data {
        let size = CGSize(width: 160, height: 96)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.2, green: 0.45, blue: 0.7, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(white: 0.95, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 56, y: 16, width: 64, height: 64))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    /// A short silent MPEG-1 Layer III stream (128 kbps, 44.1 kHz frames of zeros), generated here.
    static func mp3Data() -> Data {
        var frame = Data([0xFF, 0xFB, 0x90, 0x00])
        frame.append(Data(count: 413))
        return Data((0..<20).flatMap { _ in frame })
    }

    /// Writes the fixture media into `folder`; `withImage: false` leaves the image out.
    static func writeMedia(to folder: URL, withImage: Bool = true) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if withImage { try jpegData().write(to: folder.appending(path: imageFile)) }
        try mp3Data().write(to: folder.appending(path: soundFile))
        try mp3Data().write(to: folder.appending(path: sentenceSoundFile))
    }
}

extension Backend {
    /// Adds the two fixture note types (once) and a note of each to `deckName`, with media in `mediaFolder`.
    func seedImportedFixtures(
        deckName: String, mediaFolder: URL? = nil, withImage: Bool = true
    ) throws {
        let rows = DeckRow.rows(from: try deckTree())
        guard let deckID = rows.first(where: { $0.fullName == deckName })?.id else { return }
        try ImportedFixtures.writeMedia(to: mediaFolder ?? URL.documentsDirectory.appending(path: "collection.media"), withImage: withImage)
        let stock = try stockNotetypeJSON(kind: .basic)
        let light = try ensureFixtureNotetype(ImportedFixtures.lightName, css: ImportedFixtures.lightCSS, stock: stock)
        let dark = try ensureFixtureNotetype(ImportedFixtures.darkName, css: ImportedFixtures.darkCSS, stock: stock)
        try addNote(notetypeID: light, deckID: deckID, fields: ImportedFixtures.fieldValues(ImportedFixtures.lightNote, withMedia: true))
        try addNote(notetypeID: dark, deckID: deckID, fields: ImportedFixtures.fieldValues(ImportedFixtures.darkNote, withMedia: true))
    }

    private func ensureFixtureNotetype(_ name: String, css: String, stock: Data) throws -> Int64 {
        if let existing = try notetypeNames().first(where: { $0.name == name }) { return existing.id }
        return try addNotetype(json: try ImportedFixtures.json(basedOn: stock, name: name, css: css))
    }
}
