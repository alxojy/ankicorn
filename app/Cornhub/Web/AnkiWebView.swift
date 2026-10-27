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
        // A JSON string literal is valid JS, so the quotes inside the CSS cannot break the script.
        let literal = (try? JSONEncoder().encode(css)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        return """
            (function () {
              document.documentElement.classList.add('night-mode');
              var style = document.createElement('style');
              style.textContent = \(literal);
              document.documentElement.appendChild(style);
            })();
            """
    }

    /// `#rrggbb` with the `#` URL-escaped, for use inside an inline SVG data URI.
    static func hexEscaped(_ color: Color) -> String {
        CardWebView.hex(color).replacingOccurrences(of: "#", with: "%23")
    }

    /// Colours resolved from the Ink tokens; no raw values live here.
    static var inkCSS: String {
        let hex = CardWebView.hex
        return """
            html:root.night-mode {
              --canvas: \(hex(Theme.bg)); --canvas-elevated: \(hex(Theme.card)); --canvas-inset: \(hex(Theme.control));
              --canvas-overlay: \(hex(Theme.raised)); --canvas-code: \(hex(Theme.control));
              --fg: \(hex(Theme.text)); --fg-subtle: \(hex(Theme.text2)); --fg-faint: \(hex(Theme.muted));
              --border: \(hex(Theme.raisedHigh)); --border-subtle: \(hex(Theme.raised)); --border-strong: \(hex(Theme.muted));
              --button-bg: \(hex(Theme.raised)); --button-gradient-start: \(hex(Theme.raised));
              --button-gradient-end: \(hex(Theme.raised)); --button-hover-bg: \(hex(Theme.raisedHigh));
              --button-primary-bg: \(hex(Theme.accent)); --button-primary-gradient-start: \(hex(Theme.accent));
              --button-primary-gradient-end: \(hex(Theme.accent)); --border-focus: \(hex(Theme.accent)); --fg-link: \(hex(Theme.accent));
              --accent-card: \(hex(Theme.accent)); --accent-note: \(hex(Theme.new)); --accent-danger: \(hex(Theme.again));
              --border-radius: 12px; --border-radius-medium: \(Int(Theme.Radius.photo))px;
              --border-radius-large: \(Int(Theme.Radius.tile))px;
            }
            html, body { background: \(hex(Theme.bg)) !important; font-family: -apple-system, system-ui, sans-serif; }
            button, input, select { min-height: \(Int(Theme.minTarget))px; }
            @font-face { font-family: "Space Grotesk"; font-weight: 600; src: url("\(AnkiWebSchemeHandler.scheme)://app\(AnkiWebSchemeHandler.fontPrefix)SpaceGrotesk-SemiBold.ttf"); }
            h1, h2, h3, .h1, .h2, .h3, .title, [class*="title"], [class*="heading"] { font-family: "Space Grotesk", ui-rounded, sans-serif !important; font-weight: 600; }
            :root { --bs-primary: \(hex(Theme.accent)); --bs-link-color: \(hex(Theme.accent)); --bs-link-hover-color: \(hex(Theme.accent)); --bs-focus-ring-color: \(hex(Theme.accent)); }
            .btn-primary { --bs-btn-color: \(hex(Theme.onAccent)); --bs-btn-bg: \(hex(Theme.accent)); --bs-btn-border-color: \(hex(Theme.accent)); --bs-btn-hover-color: \(hex(Theme.onAccent)); --bs-btn-hover-bg: \(hex(Theme.accent)); --bs-btn-hover-border-color: \(hex(Theme.accent)); --bs-btn-active-color: \(hex(Theme.onAccent)); --bs-btn-active-bg: \(hex(Theme.accent)); --bs-btn-active-border-color: \(hex(Theme.accent)); --bs-btn-disabled-bg: \(hex(Theme.accent)); --bs-btn-disabled-border-color: \(hex(Theme.accent)); --bs-btn-disabled-color: \(hex(Theme.onAccent)); --bs-btn-focus-shadow-rgb: 0, 0, 0; color: \(hex(Theme.onAccent)) !important; background-color: \(hex(Theme.accent)) !important; border-color: \(hex(Theme.accent)) !important; }
            .label-button.primary, .icon-button.primary, button.primary { background: \(hex(Theme.accent)) !important; color: \(hex(Theme.onAccent)) !important; }
            .form-check-input { min-height: 0; background-color: \(hex(Theme.control)); border-color: \(hex(Theme.muted)); }
            .form-check-input:checked { background-color: \(hex(Theme.accent)) !important; border-color: \(hex(Theme.accent)) !important; }
            .form-check-input:focus { border-color: \(hex(Theme.accent)) !important; box-shadow: 0 0 0 .2rem \(hex(Theme.accent))40 !important; }
            .form-check-input:checked[type=radio] { --bs-form-check-bg-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3e%3ccircle r='2' fill='\(hexEscaped(Theme.onAccent))'/%3e%3c/svg%3e"); }
            .form-check-input:checked[type=checkbox] { --bs-form-check-bg-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20'%3e%3cpath fill='none' stroke='\(hexEscaped(Theme.onAccent))' stroke-linecap='round' stroke-linejoin='round' stroke-width='3' d='m6 10 3 3 6-6'/%3e%3c/svg%3e"); }
            .form-switch .form-check-input { --bs-form-switch-bg: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3e%3ccircle r='3' fill='\(hexEscaped(Theme.text2))'/%3e%3c/svg%3e"); background-color: \(hex(Theme.raised)); border-color: \(hex(Theme.raisedHigh)); }
            .form-switch .form-check-input:focus { --bs-form-switch-bg: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3e%3ccircle r='3' fill='\(hexEscaped(Theme.text2))'/%3e%3c/svg%3e"); }
            .form-switch .form-check-input:checked { --bs-form-switch-bg: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3e%3ccircle r='3' fill='\(hexEscaped(Theme.onAccent))'/%3e%3c/svg%3e"); }
            select, .form-select, input[type=text], input[type=number], textarea, .form-control { background-color: \(hex(Theme.control)) !important; color: \(hex(Theme.text)) !important; border-color: \(hex(Theme.raisedHigh)) !important; }
            input[type=radio], input[type=checkbox], input[type=range], progress { accent-color: \(hex(Theme.accent)); }
            .nav-tabs .nav-link.active, .tab.active, .tab-active, [role=tab][aria-selected=true] { color: \(hex(Theme.accent)) !important; border-color: \(hex(Theme.accent)) !important; border-bottom-color: \(hex(Theme.accent)) !important; }
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
