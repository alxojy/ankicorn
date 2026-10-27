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
    var fields: [String] = []
    var tags: [String] = []
    var knownTags: [String] = []
    /// Field indices that keep their value after adding, per note type.
    private(set) var sticky: [Int64: Set<Int>] = [:]
    private(set) var isLoaded = false
    var errorMessage: String?
    /// Bumped after each successful add, for haptics.
    private(set) var addedCount = 0

    init(backend: Backend, mode: Mode) {
        self.backend = backend
        self.mode = mode
    }

    var isEditing: Bool { if case .edit = mode { true } else { false } }
    var deckName: String { decks.first { $0.id == deckID }?.name ?? "Deck" }
    var notetypeName: String { notetypes.first { $0.id == notetypeID }?.name ?? "Note type" }
    var isChinese: Bool { notetypeName == ChineseNotetype.name }
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
}
