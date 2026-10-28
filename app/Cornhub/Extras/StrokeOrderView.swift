import SwiftUI
import WebKit

/// Animated stroke order for hanzi with hanzi-writer (MIT) and hanzi-writer-data (Make Me a Hanzi, Arphic Public
/// License), both loaded from jsDelivr on demand and not bundled. Shows a message when offline.
struct StrokeOrderView: UIViewRepresentable {
    let characters: [Character]
    /// Tallest a character cell gets (110) plus the scrollbar-free padding.
    static let height: CGFloat = 126

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let list = characters.prefix(24).map { "\"\($0)\"" }.joined(separator: ",")
        let html = """
            <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
            <style>body{margin:0;background:transparent;color:#9a9a9a;font:14px -apple-system;text-align:center}
            .row{display:flex;flex-wrap:nowrap;gap:8px;overflow-x:auto;padding:4px 0;-webkit-overflow-scrolling:touch}.row>div{flex:0 0 auto}svg{display:block;background:rgba(255,255,255,.06);border-radius:12px}
            </style><script src="https://cdn.jsdelivr.net/npm/hanzi-writer@3.5.0/dist/hanzi-writer.min.js"></script></head>
            <body><div class="row" id="row"></div><p id="msg"></p><script>
            if (typeof HanziWriter === 'undefined') { document.getElementById('msg').textContent = 'Stroke order needs an internet connection.'; }
            else { var chars = [\(list)];
              var size = Math.max(72, Math.min(110, Math.floor((window.innerWidth - 8 * 3) / Math.min(chars.length, 4))));
              var writers = [], running = 0;
              function play(i) { var token = ++running; (function next(j) {
                if (token !== running || j >= writers.length) { if (token === running) setTimeout(function () { play(0); }, 1200); return; }
                writers[j].animateCharacter({onComplete: function () { next(j + 1); }}); })(i); }
              chars.forEach(function (ch, i) {
                var el = document.createElement('div'); document.getElementById('row').appendChild(el);
                var w = HanziWriter.create(el, ch, {width: size, height: size, padding: 6, strokeColor: '#e8e8e8', outlineColor: '#444',
                  onLoadCharDataError: function () { document.getElementById('msg').textContent = 'Stroke data could not be loaded.'; }});
                writers.push(w);
                el.addEventListener('click', function () { running++; writers.forEach(function (x) { x.cancelQuiz && x.cancelQuiz(); });
                  w.animateCharacter({onComplete: function () { setTimeout(function () { play(0); }, 1200); }}); });
              });
              play(0);
            }
            </script></body></html>
            """
        guard context.coordinator.last != html else { return }
        context.coordinator.last = html
        view.loadHTMLString(html, baseURL: URL(string: "https://cdn.jsdelivr.net/"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator { var last = "" }
}
