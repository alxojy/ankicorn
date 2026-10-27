import SwiftUI

/// Custom study with the common options, driven by `custom_study_defaults` and `custom_study`.
struct CustomStudySheet: View {
    enum Option: String, CaseIterable, Identifiable {
        case newLimit = "Increase today's new card limit"
        case reviewLimit = "Increase today's review limit"
        case forgot = "Review forgotten cards"
        case ahead = "Review ahead"
        case preview = "Preview new cards"
        case cram = "Study by card state"
        var id: String { rawValue }
    }

    let backend: Backend
    let deckID: Int64
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var option = Option.newLimit
    @State private var amount = 10
    @State private var cram = Anki_Scheduler_CustomStudyRequest.Cram.CramKind.due
    @State private var defaults: Anki_Scheduler_CustomStudyDefaultsResponse?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Option", selection: $option) {
                    ForEach(Option.allCases) { Text($0.rawValue).tag($0) }
                }
                .listRowBackground(Theme.card)
                if option == .cram {
                    Picker("Cards", selection: $cram) {
                        Text("Due").tag(Anki_Scheduler_CustomStudyRequest.Cram.CramKind.due)
                        Text("New").tag(Anki_Scheduler_CustomStudyRequest.Cram.CramKind.new)
                        Text("Review").tag(Anki_Scheduler_CustomStudyRequest.Cram.CramKind.review)
                        Text("All").tag(Anki_Scheduler_CustomStudyRequest.Cram.CramKind.all)
                    }
                    .listRowBackground(Theme.card)
                }
                Stepper(value: $amount, in: 1...9999) { Text(unitLabel) }
                    .listRowBackground(Theme.card)
                if let errorMessage { Text(errorMessage).foregroundStyle(Theme.again) }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Custom study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { Task { await start() } }.accessibilityIdentifier("custom-study-start")
                }
            }
            .task {
                defaults = try? await backend.customStudyDefaults(deckID: deckID)
                if let defaults { amount = max(1, Int(defaults.extendNew)) }
            }
        }
    }

    private var unitLabel: String {
        switch option {
        case .newLimit, .reviewLimit, .cram: "\(amount) cards"
        case .forgot, .ahead, .preview: "\(amount) days"
        }
    }

    private func start() async {
        var request = Anki_Scheduler_CustomStudyRequest()
        request.deckID = deckID
        switch option {
        case .newLimit: request.newLimitDelta = Int32(amount)
        case .reviewLimit: request.reviewLimitDelta = Int32(amount)
        case .forgot: request.forgotDays = UInt32(amount)
        case .ahead: request.reviewAheadDays = UInt32(amount)
        case .preview: request.previewDays = UInt32(amount)
        case .cram:
            var value = Anki_Scheduler_CustomStudyRequest.Cram()
            value.kind = cram
            value.cardLimit = UInt32(amount)
            request.cram = value
        }
        do {
            try await backend.customStudy(request)
            onDone()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
