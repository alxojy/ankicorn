import SwiftUI
import WebKit

/// Renders a card's HTML in a transparent, non-interactive WKWebView over the base Ink stylesheet.
struct CardWebView: UIViewRepresentable {
    let html: String
    let css: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(MediaSchemeHandler(), forURLScheme: MediaSchemeHandler.scheme)
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.bounces = false
        // Taps and drags belong to the SwiftUI card around it.
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let document = Self.document(body: html, css: css)
        guard context.coordinator.last != document else { return }
        context.coordinator.last = document
        view.loadHTMLString(document, baseURL: URL(string: "cornhub://media/"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var last = ""
    }

    static func document(body: String, css: String) -> String {
        let style = CardStyle.decide(css: css)
        return """
            <!doctype html><html class="night_mode"><head><meta name="viewport" content="width=device-width, initial-scale=1">
            <style>\(fontAliases)\n\(baseCSS(style))\n\(css)</style>\(missingImageScript)\(mathScript)</head>
            <body class="nightMode night_mode"><div class="card nightMode night_mode">\(body)</div></body></html>
            """
    }

    /// MathJax 3 (bundled) typesets Anki's `\\(..\\)` and `\\[..\\]` math.
    static let mathScript = """
        <script>window.MathJax = { tex: { inlineMath: [['\\\\(', '\\\\)']], displayMath: [['\\\\[', '\\\\]']] },
          svg: { fontCache: 'none' } };</script>
        <script src="cornhub://app/mathjax.js" async></script>
        """

    /// Swaps an image that fails to load (WebKit would draw a "?" icon) for a small Ink placeholder.
    static let missingImageScript = """
        <script>document.addEventListener('error', function (event) {
          var image = event.target;
          if (!image || image.tagName !== 'IMG') { return; }
          var note = document.createElement('span');
          note.className = 'image-missing';
          note.textContent = 'Image missing';
          image.replaceWith(note);
        }, true);</script>
        """

    /// Faces common in shared decks that iOS lacks, mapped to installed equivalents (CJK faces to PingFang SC).
    static var fontAliases: String {
        let cjk = ["Kaiti", "KaiTi", "KaiTi_GB2312", "SimSun", "NSimSun", "SimHei", "FangSong", "STSong", "STKaiti",
                   "Microsoft YaHei", "Songti", "Noto Sans CJK SC", "Noto Serif CJK SC"]
        let western = ["Gentium Plus": "Georgia", "Gentium": "Georgia", "Times New Roman": "Times New Roman"]
        var css = cjk.map { alias(family: $0, local: ["PingFangSC-Regular", "PingFang SC"]) }
        css += western.filter { $0.key != $0.value }.map { alias(family: $0.key, local: [$0.value, "Georgia"]) }
        return css.joined(separator: "\n")
    }

    private static func alias(family: String, local: [String]) -> String {
        let sources = local.map { "local(\"\($0)\")" }.joined(separator: ", ")
        return "@font-face { font-family: \"\(family)\"; src: \(sources); }"
    }

    /// Ink look for card bodies; colours are resolved from the theme tokens. A note type with an opaque light
    /// `.card` background and no text colour gets dark text (desktop's light default) on its own background.
    static func baseCSS(_ style: CardStyle = .ink) -> String {
        var text = hex(Theme.text)
        var strong = hex(Theme.accent)
        var box = ""
        switch style {
        case .ink:
            break
        case .light(let background):
            text = "#222222"
            strong = "inherit"
            box = ".card { background-color: \(background); }"
        case .dark(let background):
            box = ".card { background-color: \(background); }"
        }
        return """
            html, body { margin: 0; background: transparent; }
            body { color: \(text); font: -apple-system-body; font-size: 20px; text-align: center;
                   display: flex; align-items: center; justify-content: center; min-height: 100vh; }
            .card { width: 100%; padding: 8px; box-sizing: border-box; color: \(text); }
            \(style == .ink ? "" : ".card { min-height: 100vh; border-radius: 16px; overflow-wrap: anywhere; }")
            \(box)
            hr { border: 0; border-top: 1px solid \(hex(Theme.muted)); opacity: 0.4; margin: 16px 0; }
            b, strong { color: \(strong); }
            .typeGood { color: \(hex(Theme.accent)); } .typeBad { color: \(hex(Theme.again)); }
            .typeMissed { color: \(hex(Theme.muted)); } code#typeans { font-size: 20px; }
            #typeans { font-family: monospace; }
            img { max-width: 100%; border-radius: 20px; }
            .image-missing { display: inline-block; padding: 6px 12px; border-radius: 12px; font-size: 14px;
                             color: \(hex(Theme.muted)); background: \(hex(Theme.raised)); }
            """
    }

    static func hex(_ color: Color) -> String {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
