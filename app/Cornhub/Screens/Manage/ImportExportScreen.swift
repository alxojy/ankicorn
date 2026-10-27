import SwiftUI
import UniformTypeIdentifiers

/// CSV import and exports (`.apkg`, `.colpkg`, note and card CSV) with the share sheet.
struct ImportExportScreen: View {
    let backend: Backend?
    @State private var model = ImportExportModel()
    @State private var pickingCsv = false

    var body: some View {
        List {
            Section {
                Button {
                    pickingCsv = true
                } label: {
                    Label("Import CSV or text file", systemImage: "tablecells")
                }
                .disabled(backend == nil || model.isWorking)
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("import-csv")
            } header: {
                Text("Import")
            } footer: {
                Text("The engine detects the delimiter, columns, note type and deck. Use Import deck on the Decks tab for .apkg files.")
            }
            exportSection
            if model.isWorking {
                ProgressView().listRowBackground(Theme.bg)
            }
            if let message = model.message {
                Text(message).foregroundStyle(Theme.text2).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("export-message")
            }
            if let file = model.exported {
                ShareLink(item: file) {
                    Label("Share \(file.lastPathComponent)", systemImage: "square.and.arrow.up")
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("export-share")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Import and export")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: backend == nil) { if let backend { await model.loadDecks(backend) } }
        .fileImporter(isPresented: $pickingCsv, allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText]) {
            result in
            if let backend, case .success(let url) = result { Task { await model.importCsv(url, backend: backend) } }
        }
    }

    @ViewBuilder private var exportSection: some View {
        @Bindable var model = model
        Section {
            Picker("Scope", selection: $model.scope) {
                Text("Whole collection").tag(ExportScope.wholeCollection)
                ForEach(model.decks, id: \.id) { deck in
                    Text(deck.name).tag(ExportScope.deck(deck.id))
                }
            }
            .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
            Toggle("Include scheduling", isOn: $model.withScheduling).listRowBackground(Theme.surface)
            Toggle("Include media", isOn: $model.withMedia).listRowBackground(Theme.surface)
            ForEach(ExportKind.allCases) { kind in
                Button {
                    if let backend { Task { await model.export(kind, backend: backend) } }
                } label: {
                    Label(kind.title, systemImage: kind.symbol)
                }
                .disabled(backend == nil || model.isWorking || (kind == .colpkg && model.scope != .wholeCollection))
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("export-\(kind.rawValue)")
            }
        } header: {
            Text("Export")
        } footer: {
            Text("A collection package always covers the whole collection.")
        }
    }
}

enum ExportKind: String, CaseIterable, Identifiable {
    case apkg, colpkg, notesCsv, cardsCsv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apkg: "Export as .apkg"
        case .colpkg: "Export collection as .colpkg"
        case .notesCsv: "Export notes as CSV"
        case .cardsCsv: "Export cards as CSV"
        }
    }

    var symbol: String {
        switch self {
        case .apkg, .colpkg: "shippingbox"
        case .notesCsv, .cardsCsv: "tablecells"
        }
    }

    var fileExtension: String {
        switch self {
        case .apkg: "apkg"
        case .colpkg: "colpkg"
        case .notesCsv, .cardsCsv: "csv"
        }
    }
}

@MainActor
@Observable
final class ImportExportModel {
    struct DeckChoice: Equatable {
        let id: Int64
        let name: String
    }

    var decks: [DeckChoice] = []
    var scope: ExportScope = .wholeCollection
    var withScheduling = true
    var withMedia = true
    private(set) var isWorking = false
    private(set) var message: String?
    private(set) var exported: URL?

    private let collectionURL = URL.documentsDirectory.appending(path: "collection.anki2")

    func loadDecks(_ backend: Backend) async {
        guard let tree = try? await backend.deckTree() else { return }
        var found: [DeckChoice] = []
        func walk(_ node: Anki_Decks_DeckTreeNode, prefix: String) {
            for child in node.children {
                let name = prefix.isEmpty ? child.name : "\(prefix)::\(child.name)"
                found.append(DeckChoice(id: child.deckID, name: name))
                walk(child, prefix: name)
            }
        }
        walk(tree, prefix: "")
        decks = found
    }

    func importCsv(_ url: URL, backend: Backend) async {
        isWorking = true
        exported = nil
        message = nil
        defer { isWorking = false }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let local = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
                .appending(path: url.lastPathComponent)
            try FileManager.default.createDirectory(
                at: local.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: local)
            defer { try? FileManager.default.removeItem(at: local.deletingLastPathComponent()) }
            let metadata = try await backend.csvMetadata(path: local)
            let summary = try await backend.importCsv(path: local, metadata: metadata)
            message = "Imported: " + summary.lines.joined(separator: ", ")
        } catch {
            message = "Import failed: \(error.localizedDescription)"
        }
    }

    func export(_ kind: ExportKind, backend: Backend) async {
        isWorking = true
        exported = nil
        message = nil
        defer { isWorking = false }
        do {
            let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let stem = kind == .colpkg ? "collection" : "export"
            let file = folder.appending(path: "\(stem).\(kind.fileExtension)")
            switch kind {
            case .apkg:
                let count = try await backend.exportAnkiPackage(
                    to: file, scope: scope, withScheduling: withScheduling, withMedia: withMedia)
                message = "Exported \(count) notes"
            case .colpkg:
                try await backend.exportCollectionPackage(to: file, collection: collectionURL, includeMedia: withMedia)
                message = "Exported the collection"
            case .notesCsv:
                message = "Exported \(try await backend.exportNoteCsv(to: file, scope: scope)) notes"
            case .cardsCsv:
                message = "Exported \(try await backend.exportCardCsv(to: file, scope: scope)) cards"
            }
            exported = file
        } catch {
            message = "Export failed: \(error.localizedDescription)"
        }
    }
}
