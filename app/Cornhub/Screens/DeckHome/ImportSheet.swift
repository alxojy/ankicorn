import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Anki deck package (`.apkg`) and collection package (`.colpkg`); declared in the app's Info.plist.
    static let ankiDeckPackage = UTType(importedAs: "com.alxojy.cornhub.apkg", conformingTo: .data)
    static let ankiCollectionPackage = UTType(importedAs: "com.alxojy.cornhub.colpkg", conformingTo: .data)
    static let ankiPackages = [ankiDeckPackage, ankiCollectionPackage]
}

/// Progress, result summary or error for an import, shown as a sheet over the Decks home.
struct ImportSheet: View {
    let state: DeckHomeModel.ImportState
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            switch state {
            case .idle:
                EmptyView()
            case .importing(let message):
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text(message).font(.headline).foregroundStyle(Theme.text)
                Text("This can take a moment for large decks.").font(.footnote).foregroundStyle(Theme.muted)
            case .done(let summary):
                Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Import complete").font(.inkAnswer).foregroundStyle(Theme.text)
                VStack(spacing: 4) {
                    ForEach(summary.lines, id: \.self) { Text($0).font(.body).foregroundStyle(Theme.text2) }
                }
                .accessibilityIdentifier("import-summary")
                doneButton
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(Theme.again)
                    .accessibilityHidden(true)
                Text("Import failed").font(.inkAnswer).foregroundStyle(Theme.text)
                Text(message).font(.footnote).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                doneButton
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface)
        .presentationDetents([.medium])
        .interactiveDismissDisabled({ if case .importing = state { true } else { false } }())
    }

    private var doneButton: some View {
        Button(action: dismiss) {
            Text("Done").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Theme.accent)
        .foregroundStyle(Theme.onAccent)
    }
}
