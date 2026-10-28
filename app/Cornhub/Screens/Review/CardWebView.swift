import SwiftUI
import WebKit

/// Renders a card's HTML in a transparent, non-interactive WKWebView over the base Ink stylesheet.
struct CardWebView: UIViewRepresentable {
    let html: String
    let css: String
    /// Lets the card's SwiftUI tap ask which picture, if any, sits under a point.
    var probe: CardImageProbe?
    /// Room kept clear under the last line, so it can scroll past the replay button floating over the corner.
    var bottomInset: CGFloat = 0
    /// On the answer side, scroll to the `#answer` divider when it sits below the fold.
    var scrollsToAnswer = false

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(MediaSchemeHandler(), forURLScheme: MediaSchemeHandler.scheme)
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.bounces = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.showsVerticalScrollIndicator = false
        view.scrollView.showsHorizontalScrollIndicator = false
        // Taps and drags belong to the SwiftUI card around it, which scrolls the page itself on a vertical drag.
        view.isUserInteractionEnabled = false
        view.navigationDelegate = context.coordinator
        probe?.webView = view
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        probe?.webView = view
        view.scrollView.contentInset.bottom = bottomInset
        context.coordinator.scrollsToAnswer = scrollsToAnswer
        let document = Self.document(body: html, css: css)
        guard context.coordinator.last != document else { return }
        context.coordinator.last = document
        view.loadHTMLString(document, baseURL: URL(string: "cornhub://media/"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var last = ""
        var scrollsToAnswer = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard scrollsToAnswer else { return }
            let script = """
                (function () {
                  var a = document.getElementById('answer');
                  return a ? a.getBoundingClientRect().top + window.scrollY : null;
                })()
                """
            webView.evaluateJavaScript(script) { result, _ in
                guard let top = result as? Double, top >= webView.bounds.height else { return }
                webView.scrollView.setContentOffset(CGPoint(x: 0, y: max(0, top - 8)), animated: false)
            }
        }
    }

    static func document(body: String, css: String) -> String {
        let style = CardStyle.decide(css: css)
        return """
            <!doctype html><html class="night_mode"><head><meta name="viewport" content="width=device-width, initial-scale=1">
            <style>\(fontAliases)\n\(baseCSS(style))\n\(css)</style><style>\(imageCSS)</style>\(missingImageScript)\(mathScript)</head>
            <body class="nightMode night_mode"><div class="card nightMode night_mode">\(body)</div></body></html>
            """
    }

    /// One standard picture size, injected after the note type's CSS (and `!important`) so a deck cannot enlarge
    /// pictures. About a third of the visible card, at most 220 pt; `cornhub://app/` assets are left alone.
    static let imageMaxHeight = 220
    static var imageCSS: String {
        """
        img:not([src^="cornhub://app/"]) {
          display: block !important; margin: 8px auto !important;
          width: auto !important; height: auto !important;
          max-width: 100% !important; max-height: min(\(imageMaxHeight)px, 33vh) !important;
          object-fit: contain !important; border-radius: 20px;
        }
        """
    }

    /// MathJax 3 (bundled) typesets Anki's `\\(..\\)` and `\\[..\\]` math.
    static let mathScript = """
        <script>window.MathJax = { tex: { inlineMath: [['\\\\(', '\\\\)']], displayMath: [['\\\\[', '\\\\]']] },
          svg: { fontCache: 'none' } };</script>
        <script src="cornhub://app/mathjax.js" async></script>
        """

    /// Removes an image that fails to load (WebKit would draw a "?" icon) and trims the blank space it leaves:
    /// emptied wrappers and a trailing run of `<br>` at the end of the card.
    static let missingImageScript = """
        <script>document.addEventListener('error', function (event) {
          var image = event.target;
          if (!image || image.tagName !== 'IMG') { return; }
          var parent = image.parentElement;
          image.remove();
          while (parent && parent.tagName !== 'BODY' && !parent.classList.contains('card')
                 && !parent.textContent.trim() && !parent.querySelector('img,audio,video,svg,canvas')) {
            var up = parent.parentElement; parent.remove(); parent = up;
          }
          var card = document.querySelector('.card');
          var last = card && card.lastChild;
          while (last && ((last.nodeType === 3 && !last.textContent.trim()) || last.tagName === 'BR')) {
            var previous = last.previousSibling; last.remove(); last = previous;
          }
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
            """
    }

    static func hex(_ color: Color) -> String {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

/// Finds the card picture under a point in the card's web view, for tap-to-zoom, and scrolls the page for the
/// card's vertical drag (the web view itself takes no touches).
@MainActor
@Observable
final class CardImageProbe {
    weak var webView: WKWebView? {
        didSet {
            guard webView !== oldValue else { return }
            observers = []
            guard let scroll = webView?.scrollView else { return }
            observers = [
                scroll.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.refresh() }
                },
                scroll.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.refresh() }
                },
            ]
            refresh()
        }
    }
    private(set) var canScrollUp = false
    private(set) var canScrollDown = false
    @ObservationIgnored private var observers: [NSKeyValueObservation] = []

    var offset: CGFloat { webView?.scrollView.contentOffset.y ?? 0 }

    /// Scrolls the page to `y`, kept within the content.
    func scroll(to y: CGFloat) {
        guard let scroll = webView?.scrollView else { return }
        let most = max(0, scroll.contentSize.height + scroll.contentInset.bottom - scroll.bounds.height)
        scroll.setContentOffset(CGPoint(x: 0, y: min(max(0, y), most)), animated: false)
    }

    private func refresh() {
        guard let scroll = webView?.scrollView else { return }
        let most = scroll.contentSize.height + scroll.contentInset.bottom - scroll.bounds.height
        let up = scroll.contentOffset.y > 1
        let down = scroll.contentOffset.y < most - 1
        if up != canScrollUp { canScrollUp = up }
        if down != canScrollDown { canScrollDown = down }
    }

    /// The `src` of the picture at `point` (web view coordinates), or nil when the tap landed elsewhere.
    /// Works in page coordinates, so a scrolled card finds the picture that is actually under the finger.
    func imageSource(at point: CGPoint) async -> String? {
        guard let webView else { return nil }
        let script = """
            (function () {
              var x = \(point.x), y = \(point.y + offset);
              var images = document.images;
              for (var i = 0; i < images.length; i++) {
                var e = images[i], r = e.getBoundingClientRect();
                var top = r.top + window.scrollY, left = r.left + window.scrollX;
                if (e.src.indexOf('cornhub://app/') !== 0 && x >= left && x <= left + r.width
                    && y >= top && y <= top + r.height) { return e.src; }
              }
              return null;
            })()
            """
        return try? await webView.evaluateJavaScript(script) as? String
    }
}

/// Which way a card drag goes, decided once from its first real movement.
enum CardDragAxis {
    case vertical, horizontal

    /// Movement under this many points is too small to tell.
    static let slop: CGFloat = 8

    /// `nil` until the drag has moved past the slop; then mostly vertical scrolls, anything else grades.
    static func decide(_ translation: CGSize) -> CardDragAxis? {
        guard max(abs(translation.width), abs(translation.height)) >= slop else { return nil }
        return abs(translation.height) > abs(translation.width) ? .vertical : .horizontal
    }
}
