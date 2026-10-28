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
        configuration.userContentController.add(FitMessageProxy(context.coordinator), name: Self.fitHandler)
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
        context.coordinator.probe = probe
        probe?.webView = view
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        probe?.webView = view
        view.scrollView.contentInset.bottom = bottomInset
        context.coordinator.probe = probe
        context.coordinator.scrollsToAnswer = scrollsToAnswer
        let document = Self.document(body: html, css: css)
        if context.coordinator.last == document, context.coordinator.inset != bottomInset {
            // Same card, new bottom inset (Dynamic Type, rotation): fit again.
            context.coordinator.inset = bottomInset
            view.evaluateJavaScript(Self.refitCall(inset: bottomInset))
        }
        context.coordinator.inset = bottomInset
        guard context.coordinator.last != document else { return }
        probe?.overflows = false
        context.coordinator.last = document
        view.loadHTMLString(document, baseURL: URL(string: "cornhub://media/"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var last = ""
        var scrollsToAnswer = false
        var inset: CGFloat = 0
        weak var probe: CardImageProbe?

        @MainActor func fitReported(overflows: Bool) {
            if probe?.overflows != overflows { probe?.overflows = overflows }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(CardWebView.refitCall(inset: inset))
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

    /// Name of the script message the page posts its "still overflows" answer to.
    static let fitHandler = "cornhubFit"
    /// The shortest a picture is squeezed to, in points, before the card scrolls instead.
    static let imageFloor = 96

    static func refitCall(inset: CGFloat) -> String { "window.cornhubFit && window.cornhubFit(\(Int(inset)));" }

    /// Fits the card without scrolling when only its pictures are too tall: measures the content against the
    /// viewport (minus the bottom inset kept for the replay button), then shrinks the pictures' max-height by
    /// the overflow shared out over what each can give up above the floor. Posts whether it still overflows.
    /// Runs on load, on image load, on resize and when Swift asks (reveal, Dynamic Type, rotation).
    static var fitScript: String {
        """
        <script>(function () {
          var FLOOR = \(imageFloor), inset = 0;
          function pictures() {
            return Array.prototype.filter.call(document.querySelectorAll('.card img'), function (i) {
              return i.getAttribute('src') !== null && i.src.indexOf('cornhub://app/') !== 0; });
          }
          function need() {
            var card = document.querySelector('.card');
            if (!card) { return 0; }
            var range = document.createRange(); range.selectNodeContents(card);
            return range.getBoundingClientRect().height + 16;
          }
          window.cornhubFit = function (newInset) {
            if (typeof newInset === 'number') { inset = newInset; }
            var images = pictures();
            images.forEach(function (i) { i.style.removeProperty('max-height'); });
            var over = need() - (window.innerHeight - inset);
            var overflows = over > 0.5;
            if (overflows) {
              var heights = images.map(function (i) { return i.getBoundingClientRect().height; });
              var slack = heights.map(function (h) { return Math.max(0, h - FLOOR); });
              var total = slack.reduce(function (a, v) { return a + v; }, 0);
              if (total > 0 && over <= total) {
                images.forEach(function (i, n) {
                  i.style.setProperty('max-height', Math.floor(heights[n] - (over + 1) * slack[n] / total) + 'px', 'important');
                });
                overflows = need() - (window.innerHeight - inset) > 1;
              }
            }
            try { window.webkit.messageHandlers.\(fitHandler).postMessage(overflows); } catch (e) {}
          };
          function again() { window.cornhubFit(); }
          document.addEventListener('load', again, true);
          document.addEventListener('error', function () { setTimeout(again, 0); }, true);
          window.addEventListener('load', function () { again(); setTimeout(again, 400); });
          window.addEventListener('resize', again);
        })();</script>
        """
    }

    static func document(body: String, css: String) -> String {
        """
        <!doctype html><html class="night_mode"><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <style>\(fontAliases)\n\(baseCSS())\n\(css)</style><style>\(backgroundOverrideCSS)\n\(imageCSS)</style>\(missingImageScript)\(fitScript)\(contrastScript)\(mathScript)</head>
        <body class="nightMode night_mode"><div class="card nightMode night_mode">\(body)</div></body></html>
        """
    }

    /// Whatever the note type says, only the Ink card colour shows: its background colours and images on
    /// `html`, `body` and `.card` are overridden after its CSS. Nothing in the collection changes.
    static var backgroundOverrideCSS: String {
        """
        html, body, .card, .nightMode, .nightMode.card, .night_mode, .night_mode.card, .nightMode .card, .night_mode .card {
          background: \(hex(Theme.card)) !important; background-color: \(hex(Theme.card)) !important;
          background-image: none !important;
        }
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

    /// Ink look for card bodies; colours are resolved from the theme tokens. Fonts, sizes and layout come from
    /// the note type's own CSS.
    static func baseCSS() -> String {
        let text = hex(Theme.text)
        return """
            html, body { margin: 0; background: \(hex(Theme.card)); }
            body { color: \(text); font: -apple-system-body; font-size: 20px; text-align: center;
                   display: flex; align-items: center; justify-content: center; min-height: 100vh; }
            .card { width: 100%; padding: 8px; box-sizing: border-box; color: \(text); min-height: 100vh;
                    overflow-wrap: anywhere; }
            hr { border: 0; border-top: 1px solid \(hex(Theme.muted)); opacity: 0.4; margin: 16px 0; }
            b, strong { color: \(hex(Theme.accent)); }
            .typeGood { color: \(hex(Theme.accent)); } .typeBad { color: \(hex(Theme.again)); }
            .typeMissed { color: \(hex(Theme.muted)); } code#typeans { font-size: 20px; }
            #typeans { font-family: monospace; }
            img { max-width: 100%; border-radius: 20px; }
            """
    }

    /// WCAG AA floor for text on the Ink card, run on computed colours after load (the answer side is a new
    /// document, so it runs again on reveal). Greys and near-black become the Ink `text` or `muted` colour;
    /// coloured text keeps its hue and is lightened until it reaches 4.5:1. No CSS is rewritten.
    static var contrastScript: String {
        """
        <script>window.addEventListener('load', function () {
          var BG = '\(hex(Theme.card))', TEXT = '\(hex(Theme.text))', MUTED = '\(hex(Theme.muted))';
          function parse(h) { return [1, 3, 5].map(function (i) { return parseInt(h.slice(i, i + 2), 16); }); }
          function lum(c) { return c.map(function (v) { v /= 255;
            return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); })
            .reduce(function (a, v, i) { return a + v * [0.2126, 0.7152, 0.0722][i]; }, 0); }
          function ratio(a, b) { var x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); }
          function toHsl(c) { var r = c[0] / 255, g = c[1] / 255, b = c[2] / 255;
            var mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, h = 0, s = 0, d = mx - mn;
            if (d) { s = d / (1 - Math.abs(2 * l - 1));
              h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4; }
            return [(h * 60 + 360) % 360, s, l]; }
          function fromHsl(h, s, l) { var k = (1 - Math.abs(2 * l - 1)) * s, x = k * (1 - Math.abs((h / 60) % 2 - 1)), m = l - k / 2;
            var p = h < 60 ? [k, x, 0] : h < 120 ? [x, k, 0] : h < 180 ? [0, k, x] : h < 240 ? [0, x, k] : h < 300 ? [x, 0, k] : [k, 0, x];
            return p.map(function (v) { return Math.round((v + m) * 255); }); }
          var back = parse(BG), text = parse(TEXT), muted = parse(MUTED);
          document.querySelectorAll('.card *').forEach(function (el) {
            var own = Array.prototype.some.call(el.childNodes, function (n) { return n.nodeType === 3 && n.textContent.trim(); });
            if (!own) { return; }
            var m = getComputedStyle(el).color.match(/[\\d.]+/g);
            if (!m) { return; }
            var c = m.slice(0, 3).map(Number);
            if (ratio(c, back) >= 4.5) { return; }
            var hsl = toHsl(c), out;
            if (hsl[1] < 0.15) {
              out = lum(c) < 0.05 || ratio(muted, back) < 4.5 ? text : muted;
            } else {
              var l = hsl[2], t = 0;
              out = c;
              while (ratio(out, back) < 4.5 && t++ < 100) { l = Math.min(1, l + 0.01); out = fromHsl(hsl[0], hsl[1], l); }
            }
            el.style.setProperty('color', 'rgb(' + out.join(',') + ')', 'important');
            el.setAttribute('data-ink-color', out.join(','));
          });
        });</script>
        """
    }

    static func hex(_ color: Color) -> String {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

/// Keeps the page's script-message handler from retaining the coordinator through the web view's configuration.
private final class FitMessageProxy: NSObject, WKScriptMessageHandler {
    weak var target: CardWebView.Coordinator?
    init(_ target: CardWebView.Coordinator) { self.target = target }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let overflows = message.body as? Bool else { return }
        Task { @MainActor in target?.fitReported(overflows: overflows) }
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
    /// Whether the card still doesn't fit after the pictures were squeezed; only then does it scroll or fade.
    var overflows = false {
        didSet { if overflows != oldValue { refresh() } }
    }
    @ObservationIgnored private var observers: [NSKeyValueObservation] = []

    var offset: CGFloat { webView?.scrollView.contentOffset.y ?? 0 }

    /// Scrolls the page to `y`, kept within the content.
    func scroll(to y: CGFloat) {
        guard let scroll = webView?.scrollView else { return }
        let most = overflows ? max(0, scroll.contentSize.height + scroll.contentInset.bottom - scroll.bounds.height) : 0
        scroll.setContentOffset(CGPoint(x: 0, y: min(max(0, y), most)), animated: false)
    }

    private func refresh() {
        guard let scroll = webView?.scrollView else { return }
        let most = scroll.contentSize.height + scroll.contentInset.bottom - scroll.bounds.height
        let up = overflows && scroll.contentOffset.y > 1
        let down = overflows && scroll.contentOffset.y < most - 1
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
