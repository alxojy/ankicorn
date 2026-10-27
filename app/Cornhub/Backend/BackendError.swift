import Foundation

/// An error reported by the engine, decoded from its `BackendError` protobuf.
struct BackendError: Error, Equatable, LocalizedError {
    var kind: Anki_Backend_BackendError.Kind
    var message: String
    var helpPage: Anki_Links_HelpPageLinkRequest.HelpPage?
    var context: String

    var errorDescription: String? { message }

    init(kind: Anki_Backend_BackendError.Kind, message: String) {
        self.kind = kind
        self.message = message
        helpPage = nil
        context = ""
    }

    init(_ proto: Anki_Backend_BackendError) {
        kind = proto.kind
        message = proto.message
        helpPage = proto.hasHelpPage ? proto.helpPage : nil
        context = proto.context
    }

    /// Decodes the bytes the bridge returns on failure; undecodable bytes become an `invalidInput` error.
    static func decode(_ data: Data) -> BackendError {
        guard let proto = try? Anki_Backend_BackendError(serializedBytes: data) else {
            return BackendError(kind: .invalidInput, message: "undecodable engine error")
        }
        return BackendError(proto)
    }
}
