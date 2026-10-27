import SwiftUI
import WebKit

/// One of Anki's own pages, hosted in the app.
enum AnkiWebPage: Identifiable, Equatable {
    case deckOptions(deckID: Int64)
    case cardInfo(cardID: Int64)
    case graphs

    var id: String { path }

    /// `#night` switches the page to its dark theme.
    var path: String {
        switch self {
        case .deckOptions(let deckID): "deck-options/\(deckID)"
        case .cardInfo(let cardID): "card-info/\(cardID)"
        case .graphs: "graphs"
        }
    }

    var title: String {
        switch self {
        case .deckOptions: "Deck options"
        case .cardInfo: "Card info"
        case .graphs: "Stats"
        }
    }

    var url: URL {
        URL(string: "\(AnkiWebSchemeHandler.scheme)://app/\(path)#night")!
    }
}

/// A WKWebView showing an Anki page over the `/_anki/*` bridge, with the Ink look injected.
struct AnkiWebView: UIViewRepresentable {
    let page: AnkiWebPage
    let backend: Backend
    let events: AnkiWebEvents
    @Binding var failure: String?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.setURLSchemeHandler(
            AnkiWebSchemeHandler(api: AnkiWebAPI(backend: backend, events: events)),
            forURLScheme: AnkiWebSchemeHandler.scheme)
        configuration.userContentController.addUserScript(
            WKUserScript(source: Self.inkScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = UIColor(Theme.bg)
        view.scrollView.backgroundColor = UIColor(Theme.bg)
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url: page.url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(failure: $failure) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let failure: Binding<String?>

        init(failure: Binding<String?>) {
            self.failure = failure
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            failure.wrappedValue = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            failure.wrappedValue = error.localizedDescription
        }
    }

    /// Dark mode plus the Ink override of Anki's CSS variables (`ts/lib/sass/_vars.scss`), injected before the page runs.
    static var inkScript: String {
        let css = inkCSS.replacingOccurrences(of: "\n", with: " ")
        return """
            (function () {
              document.documentElement.classList.add('night-mode');
              var style = document.createElement('style');
              style.textContent = "\(css)";
              document.documentElement.appendChild(style);
            })();
            """
    }

    /// Colours resolved from the Ink tokens; no raw values live here.
    static var inkCSS: String {
        let hex = CardWebView.hex
        return """
            :root.night-mode {
              --canvas: \(hex(Theme.bg)); --canvas-elevated: \(hex(Theme.card)); --canvas-inset: \(hex(Theme.control));
              --canvas-overlay: \(hex(Theme.raised)); --canvas-code: \(hex(Theme.control));
              --fg: \(hex(Theme.text)); --fg-subtle: \(hex(Theme.text2)); --fg-faint: \(hex(Theme.muted));
              --border: \(hex(Theme.raisedHigh)); --border-subtle: \(hex(Theme.raised)); --border-strong: \(hex(Theme.muted));
              --button-bg: \(hex(Theme.raised)); --button-gradient-start: \(hex(Theme.raised));
              --button-gradient-end: \(hex(Theme.raised)); --button-hover-bg: \(hex(Theme.raisedHigh));
              --button-primary-bg: \(hex(Theme.accent)); --button-primary-gradient-start: \(hex(Theme.accent));
              --button-primary-gradient-end: \(hex(Theme.accent)); --border-focus: \(hex(Theme.accent));
              --accent-card: \(hex(Theme.accent)); --accent-note: \(hex(Theme.new)); --accent-danger: \(hex(Theme.again));
              --border-radius: 12px; --border-radius-medium: \(Int(Theme.Radius.photo))px;
              --border-radius-large: \(Int(Theme.Radius.tile))px;
            }
            html, body { background: \(hex(Theme.bg)) !important; font-family: -apple-system, system-ui, sans-serif; }
            button, input, select { min-height: \(Int(Theme.minTarget))px; }
            """
    }
}

/// Anki page in a sheet: Done button, loading state and a designed error state when the pages were not built.
struct AnkiWebSheet: View {
    let page: AnkiWebPage
    let backend: Backend
    var onDone: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var events = AnkiWebEvents()
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            AnkiWebContent(page: page, backend: backend, events: events)
                .background(Theme.bg.ignoresSafeArea())
                .navigationTitle(page.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { close() }
                            .accessibilityIdentifier("web-done")
                    }
                }
        }
        .tint(Theme.accent)
        .onAppear {
            events.onClose = { close() }
            events.openLink = { UIApplication.shared.open($0) }
        }
    }

    private func close() {
        onDone()
        dismiss()
    }
}

/// The page itself, or the explanation when the bundle has no built pages.
struct AnkiWebContent: View {
    let page: AnkiWebPage
    let backend: Backend
    let events: AnkiWebEvents
    @State private var failure: String?

    var body: some View {
        if AnkiWebSchemeHandler.pagesFolder == nil {
            AnkiWebErrorView(message: "The Anki web pages are not in this build. Run scripts/build-web.sh, then rebuild the app.")
        } else if let failure {
            AnkiWebErrorView(message: failure)
        } else {
            AnkiWebView(page: page, backend: backend, events: events, failure: $failure)
                .accessibilityIdentifier("anki-web-\(page.path.split(separator: "/").first ?? "")")
        }
    }
}

struct AnkiWebErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Page unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        }
        .foregroundStyle(Theme.text)
        .accessibilityIdentifier("anki-web-error")
    }
}

#Preview("Error") {
    AnkiWebErrorView(message: "The Anki web pages are not in this build.")
        .background(Theme.bg)
}
