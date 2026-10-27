import Foundation

/// One playable item found in a card side.
enum AVItem: Equatable {
    case file(String)
    case tts(text: String, lang: String, voices: [String], speed: Float)
}

extension Backend {
    /// `extract_av_tags`: the side's HTML with play placeholders removed, plus its sounds and TTS tags.
    func extractAvTags(text: String, question: Bool) throws -> (text: String, items: [AVItem]) {
        var request = Anki_CardRendering_ExtractAvTagsRequest()
        request.text = text
        request.questionSide = question
        let response: Anki_CardRendering_ExtractAvTagsResponse = try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.extractAvTags, request)
        let items = response.avTags.compactMap { tag -> AVItem? in
            switch tag.value {
            case .soundOrVideo(let name): .file(name)
            case .tts(let tts): .tts(text: tts.fieldText, lang: tts.lang, voices: tts.voices, speed: tts.speed)
            case nil: nil
            }
        }
        return (response.text, items)
    }

    /// `compare_answer`: the engine's typed-answer diff as HTML.
    func compareAnswer(expected: String, provided: String) throws -> String {
        var request = Anki_CardRendering_CompareAnswerRequest()
        request.expected = expected
        request.provided = provided
        request.combining = true
        let response: Anki_Generic_String = try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.compareAnswer, request)
        return response.val
    }

    /// `extract_cloze_for_typing`: the text to type for cloze number `ordinal`.
    func extractClozeForTyping(text: String, ordinal: UInt32) throws -> String {
        var request = Anki_CardRendering_ExtractClozeForTypingRequest()
        request.text = text
        request.ordinal = ordinal
        let response: Anki_Generic_String = try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.extractClozeForTyping,
            request)
        return response.val
    }

    /// `all_tts_voices`: engine voice ids and names (informational; playback uses the system voices).
    func allTtsVoices() throws -> [String] {
        var request = Anki_CardRendering_AllTtsVoicesRequest()
        request.validate = false
        let response: Anki_CardRendering_AllTtsVoicesResponse = try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.allTtsVoices, request)
        return response.voices.map(\.id)
    }

    /// `get_field_names` of a notetype.
    func fieldNames(notetypeID: Int64) throws -> [String] {
        var request = Anki_Notetypes_NotetypeId()
        request.ntid = notetypeID
        let response: Anki_Generic_StringList = try call(
            service: ServiceIndex.Notetypes.service, method: ServiceIndex.Notetypes.getFieldNames, request)
        return response.vals
    }
}
