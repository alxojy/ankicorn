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
        events.webView = view
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

    /// Phone layout for `ConfigSelector.svelte`'s `.button-bar` (preset select + Save split button): 16 pt margins,
    /// equal 44 pt heights, accent Save with an attached chevron segment, and a truncating preset name.
    static var deckOptionsHeaderCSS: String {
        let hex = CardWebView.hex
        let height = Int(Theme.minTarget)
        let radius = Int(Theme.Radius.photo)
        return """
            *:has(> .button-bar) { background: \(hex(Theme.bg)) !important; border-bottom: 1px solid \(hex(Theme.raised)) !important; box-sizing: border-box; max-width: 100vw; }
            .button-bar { display: flex !important; flex-wrap: nowrap !important; align-items: center; gap: 8px; box-sizing: border-box; width: 100%; max-width: 100vw; margin: 0 !important; padding: 8px max(16px, env(safe-area-inset-right)) 8px max(16px, env(safe-area-inset-left)); overflow: hidden; }
            .button-bar > :first-child { flex: 1 1 0 !important; min-width: 0; margin: 0 !important; }
            .button-bar select, .button-bar .select, .button-bar [class*="select"] { box-sizing: border-box; width: 100%; min-width: 0; height: \(height)px; min-height: \(height)px; border-radius: \(radius)px; background-color: \(hex(Theme.control)); color: \(hex(Theme.text)); text-overflow: ellipsis; white-space: nowrap; overflow: hidden; }
            .button-bar > .d-flex { flex: none; align-items: stretch; height: \(height)px; gap: 1px; }
            .button-bar > .d-flex .save { margin: 0 4px; }
            .button-bar > .d-flex button { box-sizing: border-box; height: \(height)px; min-height: \(height)px; margin: 0; border-radius: 0; }
            .button-bar > .d-flex > :first-child button { min-width: 64px; border-radius: \(radius)px 0 0 \(radius)px; background: \(hex(Theme.accent)) !important; color: \(hex(Theme.onAccent)) !important; border-color: \(hex(Theme.accent)) !important; }
            .button-bar > .d-flex button.chevron, .button-bar > .d-flex > :last-child button { width: \(height)px; min-width: \(height)px; padding: 0; border-radius: 0 \(radius)px \(radius)px 0; background: \(hex(Theme.accent)) !important; color: \(hex(Theme.onAccent)) !important; border-color: \(hex(Theme.accent)) !important; border-left: 1px solid \(hex(Theme.onAccent))40 !important; }
            """
    }

    /// Every `Select.svelte` on the hosted pages (preset picker, gather order…): a one-line 44 pt field with a centred
    /// chevron, and its portalled `Popover.svelte` list as an Ink raised surface with 44 pt rows and an accent check.
    /// The list is placed by Anki's floating-ui; CSS only restyles it and lifts it above the page's sections.
    static var selectCSS: String {
        let hex = CardWebView.hex
        let height = Int(Theme.minTarget)
        let radius = Int(Theme.Radius.control)
        let menuRadius = Int(Theme.Radius.menu)
        return """
            .select-container { box-sizing: border-box; display: flex !important; flex-flow: row nowrap; align-items: stretch !important; width: 100%; height: \(height)px !important; min-height: \(height)px; padding: 0 !important; border-radius: \(radius)px !important; background: \(hex(Theme.control)) !important; color: \(hex(Theme.text)) !important; border: 1px solid \(hex(Theme.raisedHigh)) !important; line-height: 1.2 !important; overflow: hidden; }
            .select-container > .inner { flex: 1 1 0; min-width: 0; position: relative; display: flex; align-items: center; }
            .select-container > .inner > .label { position: static !important; display: block; width: 100%; padding: 0 12px; line-height: \(height - 2)px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
            .select-container > .chevron { flex: none; width: \(height)px; height: auto !important; align-self: stretch !important; display: flex; align-items: center; justify-content: center; border: none !important; color: \(hex(Theme.text2)); }
            .floating { z-index: 10000 !important; border-radius: \(menuRadius)px; }
            .popover-wrapper { min-height: 0 !important; }
            .popover { box-sizing: border-box; width: var(--popover-width, auto); max-width: calc(100vw - 32px); max-height: min(60vh, \(height * 7)px) !important; padding: 6px !important; border-radius: \(menuRadius)px !important; background: \(hex(Theme.raised)) !important; border: 1px solid \(hex(Theme.raisedHigh)) !important; box-shadow: 0 12px 32px rgba(0, 0, 0, 0.45) !important; overflow-x: hidden; overflow-y: auto; -webkit-overflow-scrolling: touch; }
            .popover .dropdown-item { box-sizing: border-box; display: flex !important; align-items: center; width: 100%; min-height: \(height)px; padding: 0 12px !important; border: none !important; border-radius: \(radius - 2)px !important; background: transparent !important; color: \(hex(Theme.text)) !important; font-size: 1rem !important; line-height: 1.25; white-space: normal; text-align: left; }
            .popover .dropdown-item:hover:not([disabled]), .popover .dropdown-item.focus { background: transparent !important; color: \(hex(Theme.text)) !important; }
            .popover .dropdown-item:active:not([disabled]) { background: \(hex(Theme.raisedHigh)) !important; }
            .popover .dropdown-item.active { font-weight: 600; }
            .popover .dropdown-item.active::after { content: "\\2713"; margin-left: auto; padding-left: 12px; color: \(hex(Theme.accent)); font-weight: 700; }
            .popover .dropdown-item[disabled] { color: \(hex(Theme.muted)) !important; }
            """
    }

    /// `TitledContainer.svelte` sections: title and help button on one centred row in the section-title size,
    /// the help button a muted 44 pt target instead of a white filled circle, hairline kept under the row.
    static var sectionHeaderCSS: String {
        let hex = CardWebView.hex
        let height = Int(Theme.minTarget)
        return """
            .container > .position-relative:has(> h1) { display: flex; align-items: center; justify-content: space-between; min-height: \(height)px; border-bottom: 1px solid \(hex(Theme.raisedHigh)); margin-bottom: 4px; }
            .container > .position-relative > h1 { flex: 1 1 auto; min-width: 0; margin: 0 !important; padding: 0 !important; border: none !important; font-size: \(Int(DisplaySize.sectionHeading) - 4)px !important; line-height: 1.2; }
            .container > .position-relative > .help-badge { position: static !important; flex: none; display: flex; align-items: center; justify-content: center; margin-right: -12px; color: \(hex(Theme.muted)) !important; }
            .help-badge .badge { box-sizing: border-box; display: flex; align-items: center; justify-content: center; min-width: \(height)px; min-height: \(height)px; padding: 0; background: transparent !important; border: none !important; box-shadow: none !important; color: \(hex(Theme.muted)) !important; }
            .help-badge .badge svg { fill: currentColor; }
            """
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
            \(deckOptionsHeaderCSS)
            \(selectCSS)
            \(sectionHeaderCSS)
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
    @State private var askSave = false

    var body: some View {
        NavigationStack {
            AnkiWebContent(page: page, backend: backend, events: events)
                .background(Theme.bg.ignoresSafeArea())
                .navigationTitle(page.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { Task { await done() } }
                            .accessibilityIdentifier("web-done")
                    }
                }
        }
        .tint(Theme.accent)
        .confirmationDialog("Save changes?", isPresented: $askSave, titleVisibility: .visible) {
            Button("Save") { save() }
            Button("Discard", role: .destructive) { close() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You changed the deck options.")
        }
        .onAppear {
            events.onClose = { close() }
            events.openLink = { UIApplication.shared.open($0) }
        }
    }

    /// Done on deck options asks the page whether it has unsaved edits (`anki.deckOptionsPendingChanges`, the hook
    /// desktop Anki calls on close). The page's own `confirm()` is stubbed to learn the answer; with no edits the
    /// page closes itself, with edits we ask Save / Discard / Cancel.
    private func done() async {
        guard case .deckOptions = page, let view = events.webView else { return close() }
        let script = """
            let dirty = false;
            const original = window.confirm;
            window.confirm = () => { dirty = true; return false; };
            try { await window.anki.deckOptionsPendingChanges(); } finally { window.confirm = original; }
            return dirty;
            """
        let result = try? await view.callAsyncJavaScript(script, contentWorld: .page)
        if (result as? Bool) == true { askSave = true } else { close() }
    }

    /// Triggers the page's Save the way its button does (the Control+Enter shortcut); the page then asks to close.
    private func save() {
        let script = """
            document.dispatchEvent(new KeyboardEvent('keydown',
              { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, ctrlKey: true, bubbles: true }));
            """
        Task { _ = try? await events.webView?.evaluateJavaScript(script) }
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
