import Foundation

/// Invented notes for the `--seed-sample` demo launch: HSK-style vocabulary plus a few Basic and Cloze notes.
enum SampleNotes {
    /// Hanzi, pinyin, English, example, example pinyin, example English.
    static let vocab: [[String]] = [
        ["你好", "nǐ hǎo", "hello", "<b>你好</b>，我叫小明。", "Nǐ hǎo, wǒ jiào Xiǎomíng.", "Hello, my name is Xiaoming."],
        ["谢谢", "xièxie", "thank you", "<b>谢谢</b>你的帮助。", "Xièxie nǐ de bāngzhù.", "Thank you for your help."],
        ["再见", "zàijiàn", "goodbye", "明天<b>再见</b>！", "Míngtiān zàijiàn!", "See you tomorrow!"],
        ["学生", "xuésheng", "student", "他是<b>学生</b>。", "Tā shì xuésheng.", "He is a student."],
        ["老师", "lǎoshī", "teacher", "我的<b>老师</b>很好。", "Wǒ de lǎoshī hěn hǎo.", "My teacher is very nice."],
        ["朋友", "péngyou", "friend", "她是我的<b>朋友</b>。", "Tā shì wǒ de péngyou.", "She is my friend."],
        ["水", "shuǐ", "water", "我想喝<b>水</b>。", "Wǒ xiǎng hē shuǐ.", "I want to drink water."],
        ["茶", "chá", "tea", "他喜欢喝<b>茶</b>。", "Tā xǐhuan hē chá.", "He likes drinking tea."],
        ["吃", "chī", "to eat", "我们去<b>吃</b>饭吧。", "Wǒmen qù chī fàn ba.", "Let's go eat."],
        ["喝", "hē", "to drink", "你要<b>喝</b>什么？", "Nǐ yào hē shénme?", "What would you like to drink?"],
        ["去", "qù", "to go", "我明天<b>去</b>学校。", "Wǒ míngtiān qù xuéxiào.", "I go to school tomorrow."],
        ["来", "lái", "to come", "请<b>来</b>我家。", "Qǐng lái wǒ jiā.", "Please come to my home."],
        ["看", "kàn", "to look, to watch", "我们一起<b>看</b>电影。", "Wǒmen yìqǐ kàn diànyǐng.", "Let's watch a film together."],
        ["说", "shuō", "to speak", "她会<b>说</b>中文。", "Tā huì shuō Zhōngwén.", "She can speak Chinese."],
        ["大", "dà", "big", "这个房子很<b>大</b>。", "Zhège fángzi hěn dà.", "This house is very big."],
        ["小", "xiǎo", "small", "那只猫很<b>小</b>。", "Nà zhī māo hěn xiǎo.", "That cat is very small."],
        ["今天", "jīntiān", "today", "<b>今天</b>天气很好。", "Jīntiān tiānqì hěn hǎo.", "The weather is nice today."],
        ["明天", "míngtiān", "tomorrow", "<b>明天</b>是星期五。", "Míngtiān shì xīngqīwǔ.", "Tomorrow is Friday."],
        ["书", "shū", "book", "这本<b>书</b>很有意思。", "Zhè běn shū hěn yǒu yìsi.", "This book is interesting."],
        ["家", "jiā", "home, family", "我<b>家</b>有四个人。", "Wǒ jiā yǒu sì ge rén.", "My family has four people."]
    ]

    static let basic: [[String]] = [
        ["What is the capital of China?", "Beijing"],
        ["How many tones does Mandarin have?", "Four, plus the neutral tone"]
    ]

    /// Notes for the second sample deck, so scoping and deleting in Browse have something to act on.
    static let hsk2: [[String]] = [
        ["How do you say \"I am hungry\"?", "我饿了 (wǒ è le)"],
        ["How do you say \"how much is it?\"", "多少钱 (duōshao qián)"],
        ["How do you say \"I don't understand\"?", "我不懂 (wǒ bù dǒng)"],
        ["How do you say \"please wait\"?", "请等一下 (qǐng děng yíxià)"]
    ]

    static let cloze: [[String]] = [
        ["Mandarin Chinese has {{c1::four}} tones and a {{c2::neutral}} tone.", ""],
        ["The character {{c1::水}} means water.", ""]
    ]
}

extension Backend {
    /// Adds the sample notes to the first sample deck. Idempotent: does nothing when the deck tree already has notes.
    func seedSampleNotes(deckNames: [String]) throws {
        let rows = DeckRow.rows(from: try deckTree())
        guard let deckID = rows.first(where: { $0.fullName == deckNames.first })?.id else { return }
        let chinese = try ensureChineseNotetype()
        let basicID = try ensureStockNotetype(named: "Basic", kind: .basic)
        let clozeID = try ensureStockNotetype(named: "Cloze", kind: .cloze)
        var existing = Anki_Search_SearchRequest()
        existing.search = "deck:*"
        let found: Anki_Search_SearchResponse = try call(
            service: ServiceIndex.Search.service, method: ServiceIndex.Search.searchNotes, existing)
        guard found.ids.isEmpty else { return }
        for row in SampleNotes.vocab {
            var fields = Array(repeating: "", count: ChineseNotetype.fields.count)
            fields[ChineseNotetype.Field.hanzi] = row[0]
            fields[ChineseNotetype.Field.pinyin] = row[1]
            fields[ChineseNotetype.Field.english] = row[2]
            fields[ChineseNotetype.Field.example] = row[3]
            fields[ChineseNotetype.Field.examplePinyin] = row[4]
            fields[ChineseNotetype.Field.exampleEnglish] = row[5]
            try addNote(notetypeID: chinese, deckID: deckID, fields: fields)
        }
        for fields in SampleNotes.basic { try addNote(notetypeID: basicID, deckID: deckID, fields: fields) }
        for fields in SampleNotes.cloze { try addNote(notetypeID: clozeID, deckID: deckID, fields: fields) }
        if let secondID = rows.first(where: { $0.fullName == deckNames.dropFirst().first })?.id {
            for fields in SampleNotes.hsk2 { try addNote(notetypeID: basicID, deckID: secondID, fields: fields) }
        }
    }
}

extension Backend {
    /// Adds a single Basic note (one new card) to the named deck, for tests that need exactly one due card.
    func seedOneDueNote(deckName: String) throws {
        let rows = DeckRow.rows(from: try deckTree())
        guard let deckID = rows.first(where: { $0.fullName == deckName })?.id else { return }
        let basicID = try ensureStockNotetype(named: "Basic", kind: .basic)
        _ = try addNote(notetypeID: basicID, deckID: deckID, fields: SampleNotes.basic[0])
    }

    /// Buries up to `limit` cards of the named deck, for tests that need something to unbury.
    @discardableResult
    func buryCards(deckName: String, limit: Int) throws -> [Int64] {
        let ids = Array(try browserSearch("\"deck:\(deckName)\"", notes: false).prefix(limit))
        for id in ids { try buryOrSuspend(cardID: id, mode: .buryUser) }
        return ids
    }
}
