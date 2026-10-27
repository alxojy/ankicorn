import SwiftUI

/// Account, sync options, backups and the basic scheduling and review preferences.
struct SettingsScreen: View {
    let sync: SyncModel
    let backend: Backend?
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
            }
            .scrollContentBackground(.hidden)
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
        Section("AnkiWeb account") {
            if sync.isSignedIn {
                LabeledContent("Signed in as", value: sync.username ?? "AnkiWeb")
                    .listRowBackground(Theme.surface)
                Button("Log out", role: .destructive) { confirmLogout = true }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-logout")
            } else {
                Button("Log in to AnkiWeb") { showLogin = true }
                    .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                    .accessibilityIdentifier("settings-login")
            }
        }
    }

    private var syncSection: some View {
        @Bindable var sync = sync
        return Section("Sync") {
            Toggle("Sync media", isOn: $sync.syncMediaEnabled).listRowBackground(Theme.surface)
            Toggle("Sync when the app opens", isOn: $sync.syncOnOpen).listRowBackground(Theme.surface)
            Button("Sync now") { if let backend { Task { await sync.sync(backend: backend) } } }
                .disabled(!sync.isSignedIn || sync.isSyncing || backend == nil)
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
            LabeledContent("Status", value: sync.statusText).listRowBackground(Theme.surface)
        }
    }

    private var backupSection: some View {
        Section {
            Button("Back up now") { if let backend { Task { await sync.backupNow(backend) } } }
                .disabled(backend == nil || sync.isSyncing)
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
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
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                .accessibilityIdentifier("pref-learn-ahead")
                Stepper(
                    "Next day starts at \(prefs.rolloverHour):00", value: prefs.rolloverBinding(backend), in: 0...23
                )
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
                Picker("New / review order", selection: prefs.mixBinding(backend)) {
                    Text("Mix").tag(Anki_Config_Preferences.Scheduling.NewReviewMix.distribute)
                    Text("Reviews first").tag(Anki_Config_Preferences.Scheduling.NewReviewMix.reviewsFirst)
                    Text("New first").tag(Anki_Config_Preferences.Scheduling.NewReviewMix.newFirst)
                }
                .frame(minHeight: Theme.minTarget).listRowBackground(Theme.surface)
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
