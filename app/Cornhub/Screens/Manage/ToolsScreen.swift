import SwiftUI

/// Check database, check media, empty cards and the media trash.
struct ToolsScreen: View {
    let backend: Backend?
    @State private var model = ToolsModel()

    var body: some View {
        List {
            Section {
                toolButton("Check database", "stethoscope", "tool-check-db") { await $0.checkDatabase(backend) }
                toolButton("Check media", "photo.on.rectangle", "tool-check-media") { await $0.checkMedia(backend) }
                toolButton("Find empty cards", "rectangle.dashed", "tool-empty-cards") {
                    await $0.findEmptyCards(backend)
                }
            } header: {
                Text("Tools")
            }
            if model.isWorking { ProgressView().listRowBackground(Theme.bg) }
            if let report = model.report {
                Section("Result") {
                    Text(report).font(.footnote).foregroundStyle(Theme.text2).textSelection(.enabled)
                        .listRowBackground(Theme.surface).accessibilityIdentifier("tool-report")
                }
            }
            actionsSection
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Tools")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var actionsSection: some View {
        if !model.unusedMedia.isEmpty {
            Section {
                Button("Move \(model.unusedMedia.count) unused files to trash", role: .destructive) {
                    Task { await model.trashUnused(backend) }
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("tool-trash-unused")
            }
        }
        if model.emptyCardCount > 0 {
            Section {
                Button("Delete \(model.emptyCardCount) empty cards", role: .destructive) {
                    Task { await model.deleteEmptyCards(backend) }
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("tool-delete-empty")
            }
        }
        if model.haveTrash {
            Section("Media trash") {
                Button("Restore trashed media") { Task { await model.restoreTrash(backend) } }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("tool-restore-trash")
                Button("Empty trash", role: .destructive) { Task { await model.emptyTrash(backend) } }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("tool-empty-trash")
            }
        }
    }

    private func toolButton(
        _ title: String, _ symbol: String, _ id: String, action: @escaping (ToolsModel) async -> Void
    ) -> some View {
        Button {
            Task { await action(model) }
        } label: {
            Label(title, systemImage: symbol)
        }
        .disabled(backend == nil || model.isWorking)
        .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
        .accessibilityIdentifier(id)
    }
}

@MainActor
@Observable
final class ToolsModel {
    private(set) var isWorking = false
    private(set) var report: String?
    private(set) var unusedMedia: [String] = []
    private(set) var haveTrash = false
    private(set) var emptyCardCount = 0
    private var emptyCardIDs: [Int64] = []

    private func run(_ work: () async throws -> String) async {
        isWorking = true
        defer { isWorking = false }
        do { report = try await work() } catch { report = "Failed: \(error.localizedDescription)" }
    }

    func checkDatabase(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            let problems = try await backend.checkDatabase()
            return problems.isEmpty ? "No problems found." : problems.joined(separator: "\n")
        }
    }

    func checkMedia(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            let result = try await backend.checkMedia()
            unusedMedia = result.unused
            haveTrash = result.haveTrash
            return result.report
        }
    }

    func findEmptyCards(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            let result = try await backend.emptyCardsReport()
            emptyCardIDs = result.notes.flatMap(\.cardIds)
            emptyCardCount = emptyCardIDs.count
            return emptyCardCount == 0 ? "No empty cards." : result.report
        }
    }

    func deleteEmptyCards(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            try await backend.removeCards(emptyCardIDs)
            let count = emptyCardIDs.count
            emptyCardIDs = []
            emptyCardCount = 0
            return "Deleted \(count) empty cards."
        }
    }

    func trashUnused(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            try await backend.trashMediaFiles(unusedMedia)
            let count = unusedMedia.count
            unusedMedia = []
            haveTrash = true
            return "Moved \(count) files to the trash."
        }
    }

    func restoreTrash(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            try await backend.restoreMediaTrash()
            haveTrash = false
            return "Restored the trashed media."
        }
    }

    func emptyTrash(_ backend: Backend?) async {
        guard let backend else { return }
        await run {
            try await backend.emptyMediaTrash()
            haveTrash = false
            return "Emptied the media trash."
        }
    }
}
