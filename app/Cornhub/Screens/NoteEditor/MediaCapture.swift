import AVFoundation
import Observation
import SwiftUI
import UIKit

/// Records one audio clip at a time with `AVAudioRecorder` into a temporary m4a file.
@MainActor @Observable
final class AudioRecorder: NSObject {
    private(set) var isRecording = false
    var failure: String?
    private var recorder: AVAudioRecorder?

    /// Starts recording after asking for microphone permission.
    func start() async {
        guard await AVAudioApplication.requestRecordPermission() else {
            failure = "Allow microphone access in Settings to record audio."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44_100, AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.record() else { throw CocoaError(.fileWriteUnknown) }
            self.recorder = recorder
            isRecording = true
        } catch {
            failure = error.localizedDescription
        }
    }

    /// Stops and returns the recorded bytes, deleting the temporary file.
    func stop() -> Data? {
        guard let recorder else { return nil }
        recorder.stop()
        self.recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
        defer { try? FileManager.default.removeItem(at: recorder.url) }
        return try? Data(contentsOf: recorder.url)
    }
}

/// The system camera, returning a JPEG.
struct CameraPicker: UIViewControllerRepresentable {
    let onPicture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                parent.onPicture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
