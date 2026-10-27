import SwiftUI

/// AnkiWeb login. The password is passed to the engine once and never kept.
struct LoginSheet: View {
    let sync: SyncModel
    let backend: Backend?
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var working = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sign in to AnkiWeb").font(.inkAnswer).foregroundStyle(Theme.text)
                Text("Use the account you sync desktop Anki with. Only a sync key is kept on this device.")
                    .font(.footnote).foregroundStyle(Theme.muted)
                field("Email") {
                    TextField("", text: $username)
                        .textContentType(.username).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("login-username")
                }
                field("Password") {
                    SecureField("", text: $password)
                        .textContentType(.password)
                        .accessibilityIdentifier("login-password")
                }
                if let error {
                    Text(error).font(.footnote).foregroundStyle(Theme.again)
                        .accessibilityIdentifier("login-error")
                }
                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if working { ProgressView() } else { Text("Log in").font(.headline) }
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                }
                .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                .tint(Theme.accent).foregroundStyle(Theme.onAccent)
                .disabled(username.isEmpty || password.isEmpty || working || backend == nil)
                .accessibilityIdentifier("login-submit")
                Spacer()
            }
            .padding(16)
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.frame(minHeight: Theme.minTarget)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).inkLabel()
            content()
                .padding(.horizontal, 14).frame(minHeight: Theme.minTarget)
                .background(Theme.control, in: RoundedRectangle(cornerRadius: Theme.Radius.photo))
                .foregroundStyle(Theme.text)
        }
    }

    private func submit() async {
        guard let backend else { return }
        working = true
        error = nil
        do {
            try await sync.login(backend: backend, username: username, password: password)
            password = ""
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        working = false
    }
}
