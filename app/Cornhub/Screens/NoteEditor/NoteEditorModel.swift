import Foundation
import Observation

/// State of the Add card and Edit note screen. All collection work goes through `Backend`.
@MainActor @Observable
final class NoteEditorModel {
    enum Mode: Equatable {
        case add
        case edit(Anki_Notes_Note)
    }

    let backend: Backend
    let mode: Mode
    var decks: [Anki_Decks_DeckNameId] = []
    var notetypes: [Anki_Notetypes_NotetypeNameId] = []
    var deckID: Int64 = 0
    private(set) var notetypeID: Int64 = 0
    private(set) var fieldNames: [String] = []
    var fields: [String] = [] {
        didSet { if fields != oldValue { scheduleAutoFill() } }
    }
    var tags: [String] = []
    var knownTags: [String] = []
    /// Field indices that keep their value after adding, per note type.
    private(set) var sticky: [Int64: Set<Int>] = [:]
    private(set) var isLoaded = false
    var errorMessage: String?
    /// Bumped after each successful add, for haptics.
    private(set) var addedCount = 0
    private(set) var isAutoFilling = false
    /// Last value the app wrote into each field; a field still holding it (or empty) may be refilled.
    private(set) var autoValues: [Int: String] = [:]
    /// Hanzi text waiting for the Translation framework, and a counter the screen watches to start a request.
    private(set) var translationSource: String?
    private(set) var translationRequest = 0
    private var autoFillTask: Task<Void, Never>?
    private var lastSources: [Int: String] = [:]

    init(backend: Backend, mode: Mode) {
        self.backend = backend
        self.mode = mode
    }

    var isEditing: Bool { if case .edit = mode { true } else { false } }
    var deckName: String { decks.first { $0.id == deckID }?.name ?? "Deck" }
    var notetypeName: String { notetypes.first { $0.id == notetypeID }?.name ?? "Note type" }
    var isChinese: Bool { notetypeName == ChineseNotetype.name }
    private func fieldIndex(_ name: String) -> Int? {
        fieldNames.firstIndex { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Add card on a note type with Hanzi, Pinyin and English fields (the bundled Chinese type or a lookalike).
    var autoFillsPinyin: Bool {
        !isEditing && fieldIndex("Hanzi") != nil && fieldIndex("Pinyin") != nil && fieldIndex("English") != nil
    }

    func isAutoFilled(_ index: Int) -> Bool {
        guard let value = autoValues[index], fields.indices.contains(index) else { return false }
        return !value.isEmpty && fields[index] == value
    }

    private func scheduleAutoFill() {
        guard autoFillsPinyin, isLoaded || !fields.isEmpty else { return }
        autoFillTask?.cancel()
        autoFillTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            applyAutoFill()
        }
    }

    /// Sets `index` to `value` unless the user has typed their own text there.
    private func setAuto(_ index: Int, _ value: String) {
        guard fields.indices.contains(index) else { return }
        let owned = fields[index].isEmpty || fields[index] == autoValues[index]
        guard owned else { return }
        if value.isEmpty { autoValues[index] = nil } else { autoValues[index] = value }
        if fields[index] != value { fields[index] = value }
    }

    /// Fills Pinyin (and Example pinyin) now, then asks for English. Skips sources that did not change.
    func applyAutoFill() {
        guard autoFillsPinyin, let hanzi = fieldIndex("Hanzi"), let pinyin = fieldIndex("Pinyin"),
            let english = fieldIndex("English")
        else { return }
        let source = CardText.plain(fields[hanzi])
        if lastSources[hanzi] != source {
            lastSources[hanzi] = source
            setAuto(pinyin, Pinyin.from(source))
            if source.isEmpty {
                setAuto(english, "")
                translationSource = nil
            } else if fields[english].isEmpty || fields[english] == autoValues[english] {
                translationSource = source
                translationRequest += 1
            }
        }
        if let example = fieldIndex("Example"), let examplePinyin = fieldIndex("Example pinyin") {
            let text = CardText.plain(fields[example])
            if lastSources[example] != text {
                lastSources[example] = text
                setAuto(examplePinyin, Pinyin.from(text))
            }
        }
    }

    /// Called by the screen with Translation's result, or nil when it is unavailable; falls back to `TextGenerator`.
    func finishTranslation(source: String, result: String?) async {
        var english = result?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if english.isEmpty, TextGenerator.isAvailable {
            english = ((try? await TextGenerator.generate(
                instructions: "You give the English meaning of a Chinese word in 1 to 4 words. Reply with only those words.",
                prompt: source)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !english.isEmpty, let hanzi = fieldIndex("Hanzi"), let target = fieldIndex("English"),
            CardText.plain(fields[hanzi]) == source
        else { return }
        setAuto(target, english)
    }

    /// Adding needs some text in the first field, as the engine requires.
    var canSubmit: Bool { !(fields.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func load() async {
        do {
            decks = try await backend.deckNames()
            notetypes = try await backend.notetypeNames()
            knownTags = (try? await backend.allTags()) ?? []
            switch mode {
            case .add:
                let defaults = try await backend.defaultsForAdding()
                deckID = decks.contains { $0.id == defaults.deckID } ? defaults.deckID : (decks.first?.id ?? 0)
                let chosen = notetypes.contains { $0.id == defaults.notetypeID } ? defaults.notetypeID : (notetypes.first?.id ?? 0)
                try await selectNotetype(chosen)
            case .edit(let note):
                notetypeID = note.notetypeID
                fieldNames = try await backend.fieldNames(notetypeID: note.notetypeID)
                fields = note.fields
                tags = note.tags
            }
            isLoaded = true
        } catch {
            errorMessage = Self.message(error)
        }
    }

    /// Switches the note type, keeping the text of sticky fields that still exist.
    func selectNotetype(_ id: Int64) async throws {
        let old = fields
        let keep = sticky[notetypeID] ?? []
        fieldNames = try await backend.fieldNames(notetypeID: id)
        notetypeID = id
        autoValues = [:]
        lastSources = [:]
        fields = fieldNames.indices.map { keep.contains($0) && $0 < old.count ? old[$0] : "" }
    }

    func chooseNotetype(_ id: Int64) {
        Task {
            do { try await selectNotetype(id) } catch { errorMessage = Self.message(error) }
        }
    }

    func isSticky(_ index: Int) -> Bool { sticky[notetypeID]?.contains(index) ?? false }

    func toggleSticky(_ index: Int) {
        if sticky[notetypeID]?.remove(index) == nil { sticky[notetypeID, default: []].insert(index) }
    }

    func addTag(_ raw: String) {
        let tag = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        guard !tag.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { return }
        tags.append(tag)
    }

    func removeTag(_ tag: String) { tags.removeAll { $0 == tag } }

    /// `add_note`; keeps the deck, note type, tags and sticky fields for the next card. Returns whether it worked.
    @discardableResult
    func add() async -> Bool {
        do {
            try await backend.addNote(notetypeID: notetypeID, deckID: deckID, fields: fields, tags: tags)
            let keep = sticky[notetypeID] ?? []
            for index in fields.indices where !keep.contains(index) { fields[index] = "" }
            autoValues = [:]
            lastSources = [:]
            addedCount += 1
            return true
        } catch {
            errorMessage = Self.message(error)
            return false
        }
    }

    /// `update_notes` for the edited note. Returns the saved note, or nil on failure.
    func save() async -> Anki_Notes_Note? {
        guard case .edit(var note) = mode else { return nil }
        note.fields = fields
        note.tags = tags
        do {
            try await backend.updateNote(note)
            return note
        } catch {
            errorMessage = Self.message(error)
            return nil
        }
    }

    /// Stores picture or audio bytes through `add_media_file` and returns the stored file name.
    func storeMedia(name: String, data: Data) async -> String? {
        do { return try await backend.addMediaFile(desiredName: name, data: data) } catch {
            errorMessage = Self.message(error)
            return nil
        }
    }

    /// The field a picture goes to: the note type's Picture field, else `fallback`.
    func pictureIndex(fallback: Int?) -> Int? {
        fieldNames.firstIndex { $0.caseInsensitiveCompare("Picture") == .orderedSame } ?? fallback
    }

    /// The field a recording goes to: the note type's Audio field, else `fallback`.
    func audioIndex(fallback: Int?) -> Int? {
        fieldNames.firstIndex { $0.caseInsensitiveCompare("Audio") == .orderedSame } ?? fallback
    }

    func append(_ html: String, toField index: Int) {
        guard fields.indices.contains(index) else { return }
        fields[index] += (fields[index].isEmpty ? "" : " ") + html
    }

    /// The next free cloze number across all fields.
    var nextClozeNumber: Int {
        let pattern = /\{\{c(\d+)::/
        let numbers = fields.flatMap { $0.matches(of: pattern).compactMap { Int($0.1) } }
        return (numbers.max() ?? 0) + 1
    }

    nonisolated static func message(_ error: Error) -> String {
        (error as? BackendError)?.message ?? error.localizedDescription
    }

    /// Fills empty example and audio fields from the first field. A picture needs an image source and is left to the
    /// user (TODO); nothing is changed when generation is unavailable.
    func autoFill() async {
        let headword = CardText.plain(fields.first ?? "")
        guard !headword.isEmpty, !isAutoFilling else { return }
        isAutoFilling = true
        defer { isAutoFilling = false }
        let language = SpeechSettings.language(deckID: deckID)
        let exampleIndices = fieldNames.indices.filter { fieldNames[$0].lowercased().hasPrefix("example") && fields[$0].isEmpty }
        if !exampleIndices.isEmpty {
            do {
                let reply = try await TextGenerator.generate(
                    instructions: "You write one short, natural example sentence for a language learner. "
                        + "Reply with exactly three lines and nothing else: the sentence, its pinyin or reading, its English translation.",
                    prompt: "Word: \(headword)")
                let lines = reply.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                for (index, line) in zip(exampleIndices, lines) { fields[index] = line }
            } catch {
                errorMessage = Self.message(error)
            }
        }
        if let audio = audioIndex(fallback: nil), fields[audio].isEmpty {
            if let data = await Speaker.render(headword, language: language),
                let name = await storeMedia(name: "cornhub-\(abs(headword.hashValue)).caf", data: data)
            {
                fields[audio] = "[sound:\(name)]"
            } else if errorMessage == nil {
                errorMessage = "Speech audio could not be generated on this device."
            }
        }
    }
}
