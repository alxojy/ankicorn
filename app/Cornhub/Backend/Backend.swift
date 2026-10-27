import Foundation
import RslibBridge
import SwiftProtobuf

/// The raw rslib handle; closes it when the last reference goes away. Only `Backend` touches it, serially.
private final class Handle: @unchecked Sendable {
    let pointer: UnsafeMutableRawPointer

    init(_ pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    deinit {
        close_backend(pointer)
    }
}

/// Owns an rslib backend handle. An actor, so calls are serialised and run off the main thread.
actor Backend {
    private let handle: Handle

    init(preferredLanguages: [String] = ["en"]) throws {
        var initMessage = Anki_Backend_BackendInit()
        initMessage.preferredLangs = preferredLanguages
        let bytes = try initMessage.serializedData()
        let opened = bytes.withUnsafeBytes { open_backend($0.bindMemory(to: UInt8.self).baseAddress, bytes.count) }
        guard let opened else {
            throw BackendError(kind: .invalidInput, message: "the engine could not be created")
        }
        handle = Handle(opened)
    }

    /// Calls an engine method with a typed request and decodes the typed response.
    func call<Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message>(
        service: UInt32, method: UInt32, _ request: Request
    ) throws -> Response {
        try perform(service: service, method: method, request)
    }

    /// Like `call` but not serialised behind other calls, so progress can be read while a long call (sync) runs.
    nonisolated func callConcurrently<Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message>(
        service: UInt32, method: UInt32, _ request: Request
    ) throws -> Response {
        try perform(service: service, method: method, request)
    }

    private nonisolated func perform<Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message>(
        service: UInt32, method: UInt32, _ request: Request
    ) throws -> Response {
        let input = try request.serializedData()
        let pointer = handle.pointer
        var out = ByteBuf(ptr: nil, len: 0, cap: 0)
        let ok = withUnsafeMutablePointer(to: &out) { outPointer in
            input.withUnsafeBytes {
                run_method(pointer, service, method, $0.bindMemory(to: UInt8.self).baseAddress, input.count, outPointer)
            }
        }
        // The buffer is copied out and freed exactly once, whatever the outcome.
        let output = out.ptr.map { Data(bytes: $0, count: out.len) } ?? Data()
        free_bytes(out)
        guard ok else { throw BackendError.decode(output) }
        return try Response(serializedBytes: output)
    }
}
