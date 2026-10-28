import SwiftUI

/// Account, sync options, backups and the basic scheduling and review preferences.
struct SettingsScreen: View {
    let sync: SyncModel
    let backend: Backend?
    var importDeck: (URL) -> Void = { _ in }
    @State private var prefs = PreferencesModel()
    @State private var showLogin = false
    @State private var confirmLogout = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                syncSection
                backupSection
                schedulingSection
                reviewSection
                SpeechAndAISection(backend: backend)
                Section {
                    NavigationLink {
                        ManageScreen(backend: backend)
                    } label: {
                        Label("Filtered decks, tags, note types", systemImage: "slider.horizontal.3")
                    }
                    .listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-manage")
                } header: {
                    Text("Manage")
                }
                Section {
                    NavigationLink {
                        ImportExportScreen(backend: backend, importDeck: importDeck)
                    } label: {
                        Label("Import and export", systemImage: "square.and.arrow.up.on.square")
                    }
                    .listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-import-export")
                    NavigationLink {
                        ToolsScreen(backend: backend)
                    } label: {
                        Label("Check database, media, empty cards", systemImage: "wrench.and.screwdriver")
                    }
                    .listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-tools")
                } header: {
                    Text("Data")
                }
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
            .background(Theme.bg)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.large)
            .listRowBackground(Theme.surface)
        }
        .task(id: backend == nil) { if let backend { await prefs.load(backend) } }
        .sheet(isPresented: $showLogin) { LoginSheet(sync: sync, backend: backend) }
        .confirmationDialog("Log out of AnkiWeb?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Log out", role: .destructive) { sync.logout() }
        }
    }

    private var accountSection: some View {
        Section {
            if sync.isSignedIn {
                LabeledContent("Signed in as", value: sync.username ?? "AnkiWeb")
                    .listRowBackground(Theme.surface)
                Button("Log out", role: .destructive) { confirmLogout = true }
                    .listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-logout")
            } else {
                Button("Log in to AnkiWeb") { showLogin = true }
                    .listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-login")
            }
        } header: {
            Text("AnkiWeb account")
        } footer: {
            if !sync.isSignedIn {
                Text("Sync your collection with desktop Anki through AnkiWeb.")
            }
        }
    }

    @ViewBuilder private var syncSection: some View {
        if sync.isSignedIn {
            @Bindable var sync = sync
            Section {
                Toggle("Sync media", isOn: $sync.syncMediaEnabled).listRowBackground(Theme.surface)
                Toggle("Sync when the app opens", isOn: $sync.syncOnOpen).listRowBackground(Theme.surface)
                Button {
                    if let backend { Task { await sync.sync(backend: backend) } }
                } label: {
                    HStack {
                        Text("Sync now")
                        Spacer()
                        if sync.isSyncing {
                            ProgressView()
                        } else if !sync.hasFailed {
                            Text(sync.statusText).font(.footnote).foregroundStyle(Theme.text2)
                        }
                    }
                }
                .disabled(sync.isSyncing || backend == nil)
                .listRowBackground(Theme.surface)
                .accessibilityIdentifier("settings-sync-now")
            } header: {
                Text("Sync")
            } footer: {
                if sync.isSyncing {
                    Text(sync.statusText)
                } else if sync.hasFailed {
                    Text(sync.statusText).foregroundStyle(Theme.again)
                }
            }
        }
    }

    private var backupSection: some View {
        Section {
            Button("Back up now") { if let backend { Task { await sync.backupNow(backend) } } }
                .disabled(backend == nil || sync.isSyncing)
                .listRowBackground(Theme.surface)
            if let last = sync.lastBackup {
                LabeledContent("Last backup", value: last.formatted(.relative(presentation: .named)))
                    .listRowBackground(Theme.surface)
            }
        } header: {
            Text("Backups")
        } footer: {
            Text("Backups are made automatically before a full sync and every so often.")
        }
    }

    @ViewBuilder private var schedulingSection: some View {
        if prefs.loaded {
            Section("Scheduling") {
                Stepper(
                    "Learn ahead: \(prefs.learnAheadMinutes) min", value: prefs.learnAheadBinding(backend), in: 0...60
                )
                .listRowBackground(Theme.surface)
                .accessibilityIdentifier("pref-learn-ahead")
                Stepper(
                    "Next day starts at \(prefs.rolloverHour):00", value: prefs.rolloverBinding(backend), in: 0...23
                )
                .listRowBackground(Theme.surface)
                Picker("New / review order", selection: prefs.mixBinding(backend)) {
                    Text("Mix").tag(Anki_Config_Preferences.Scheduling.NewReviewMix.distribute)
                    Text("Reviews first").tag(Anki_Config_Preferences.Scheduling.NewReviewMix.reviewsFirst)
                    Text("New first").tag(Anki_Config_Preferences.Scheduling.NewReviewMix.newFirst)
                }
                .listRowBackground(Theme.surface)
            }
        }
    }

    @ViewBuilder private var reviewSection: some View {
        if prefs.loaded {
            Section("Review") {
                Toggle("Show remaining card counts", isOn: prefs.toggleBinding(backend, \.showRemainingDueCounts))
                    .listRowBackground(Theme.surface)
                Toggle("Show intervals on buttons", isOn: prefs.toggleBinding(backend, \.showIntervalsOnButtons))
                    .listRowBackground(Theme.surface)
                Toggle("Hide audio play buttons", isOn: prefs.toggleBinding(backend, \.hideAudioPlayButtons))
                    .listRowBackground(Theme.surface)
                Toggle("Interrupt audio when answering", isOn: prefs.toggleBinding(backend, \.interruptAudioWhenAnswering))
                    .listRowBackground(Theme.surface)
                Stepper(
                    prefs.timeLimitMinutes == 0 ? "Study time limit: off" : "Study time limit: \(prefs.timeLimitMinutes) min",
                    value: prefs.timeLimitBinding(backend), in: 0...120, step: 5
                )
                .listRowBackground(Theme.surface)
            }
            Section("Editing and search") {
                Toggle("Add to the current deck", isOn: prefs.editingBinding(backend, \.addingDefaultsToCurrentDeck))
                    .listRowBackground(Theme.surface)
                Toggle("Paste without formatting", isOn: prefs.editingBinding(backend, \.pasteStripsFormatting))
                    .listRowBackground(Theme.surface)
                Toggle("Paste images as PNG", isOn: prefs.editingBinding(backend, \.pasteImagesAsPng))
                    .listRowBackground(Theme.surface)
                Toggle("Ignore accents in search", isOn: prefs.editingBinding(backend, \.ignoreAccentsInSearch))
                    .listRowBackground(Theme.surface)
                Toggle("Render LaTeX", isOn: prefs.editingBinding(backend, \.renderLatex))
                    .listRowBackground(Theme.surface)
            }
        } else if backend != nil {
            ProgressView().listRowBackground(Theme.bg)
        }
    }
}

/// Reads and writes the engine's preferences; every change is saved at once with `set_preferences`.
@MainActor
@Observable
final class PreferencesModel {
    private(set) var loaded = false
    private var value = Anki_Config_Preferences()

    var learnAheadMinutes: Int { Int(value.scheduling.learnAheadSecs / 60) }
    var rolloverHour: Int { Int(value.scheduling.rollover) }

    var timeLimitMinutes: Int { Int(value.reviewing.timeLimitSecs / 60) }

    func timeLimitBinding(_ backend: Backend?) -> Binding<Int> {
        Binding(get: { self.timeLimitMinutes }, set: { minutes in
            self.update(backend) { $0.reviewing.timeLimitSecs = UInt32(minutes * 60) }
        })
    }

    func editingBinding(_ backend: Backend?, _ keyPath: WritableKeyPath<Anki_Config_Preferences.Editing, Bool>)
        -> Binding<Bool>
    {
        Binding(get: { self.value.editing[keyPath: keyPath] }, set: { isOn in
            self.update(backend) { $0.editing[keyPath: keyPath] = isOn }
        })
    }

    func load(_ backend: Backend) async {
        if let loadedValue = try? await backend.getPreferences() {
            value = loadedValue
            loaded = true
        }
    }

    func learnAheadBinding(_ backend: Backend?) -> Binding<Int> {
        Binding(get: { self.learnAheadMinutes }, set: { minutes in
            self.update(backend) { $0.scheduling.learnAheadSecs = UInt32(minutes * 60) }
        })
    }

    func rolloverBinding(_ backend: Backend?) -> Binding<Int> {
        Binding(get: { self.rolloverHour }, set: { hour in
            self.update(backend) { $0.scheduling.rollover = UInt32(hour) }
        })
    }

    func mixBinding(_ backend: Backend?) -> Binding<Anki_Config_Preferences.Scheduling.NewReviewMix> {
        Binding(get: { self.value.scheduling.newReviewMix }, set: { mix in
            self.update(backend) { $0.scheduling.newReviewMix = mix }
        })
    }

    func toggleBinding(_ backend: Backend?, _ keyPath: WritableKeyPath<Anki_Config_Preferences.Reviewing, Bool>)
        -> Binding<Bool>
    {
        Binding(get: { self.value.reviewing[keyPath: keyPath] }, set: { isOn in
            self.update(backend) { $0.reviewing[keyPath: keyPath] = isOn }
        })
    }

    private func update(_ backend: Backend?, _ change: (inout Anki_Config_Preferences) -> Void) {
        change(&value)
        guard let backend else { return }
        let saved = value
        Task { try? await backend.setPreferences(saved) }
    }
}
