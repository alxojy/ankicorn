import Foundation

/// A card side as the engine renders it, ready for the web view.
struct RenderedCard: Equatable {
    var question: String
    var answer: String
    var css: String
}

extension Backend {
    /// `render_existing_card`: the card's question and answer HTML from its templates.
    func renderExistingCard(id: Int64) throws -> RenderedCard {
        var request = Anki_CardRendering_RenderExistingCardRequest()
        request.cardID = id
        let response: Anki_CardRendering_RenderCardResponse = try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.renderExistingCard,
            request)
        func join(_ nodes: [Anki_CardRendering_RenderedTemplateNode]) -> String {
            nodes.map { node in
                switch node.value {
                case .text(let text): text
                case .replacement(let replacement): replacement.currentText
                case nil: ""
                }
            }.joined()
        }
        return RenderedCard(
            question: join(response.questionNodes), answer: join(response.answerNodes), css: response.css)
    }

    /// `render_uncommitted_card`: how `note` would render with `template` before it is saved (the layout preview).
    func renderUncommittedCard(
        note: Anki_Notes_Note, ordinal: Int, template: Anki_Notetypes_Notetype.Template
    ) throws -> RenderedCard {
        var request = Anki_CardRendering_RenderUncommittedCardRequest()
        request.note = note
        request.cardOrd = UInt32(ordinal)
        request.template = template
        let response: Anki_CardRendering_RenderCardResponse = try call(
            service: ServiceIndex.CardRendering.service, method: ServiceIndex.CardRendering.renderUncommittedCard,
            request)
        func join(_ nodes: [Anki_CardRendering_RenderedTemplateNode]) -> String {
            nodes.map { node in
                switch node.value {
                case .text(let text): text
                case .replacement(let replacement): replacement.currentText
                case nil: ""
                }
            }.joined()
        }
        return RenderedCard(
            question: join(response.questionNodes), answer: join(response.answerNodes), css: response.css)
    }

    /// `get_undo_status`: what Undo and Redo would do; an empty string means nothing to do.
    func undoStatus() throws -> Anki_Collection_UndoStatus {
        try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.getUndoStatus,
            Anki_Generic_Empty())
    }

    /// `undo`.
    func undo() throws {
        let _: Anki_Collection_OpChangesAfterUndo = try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.undo, Anki_Generic_Empty())
    }

    /// `redo`.
    func redo() throws {
        let _: Anki_Collection_OpChangesAfterUndo = try call(
            service: ServiceIndex.Collection.service, method: ServiceIndex.Collection.redo, Anki_Generic_Empty())
    }
}
