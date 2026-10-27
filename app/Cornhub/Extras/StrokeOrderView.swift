import SwiftUI
import WebKit

/// Animated stroke order for hanzi with hanzi-writer (MIT) and hanzi-writer-data (Make Me a Hanzi, Arphic Public
/// License), both loaded from jsDelivr on demand and not bundled. Shows a message when offline.
struct StrokeOrderView: UIViewRepresentable {
    let characters: [Character]

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let list = characters.prefix(8).map { "\"\($0)\"" }.joined(separator: ",")
        let html = """
            <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
            <style>body{margin:0;background:transparent;color:#9a9a9a;font:14px -apple-system;text-align:center}
            .row{display:flex;flex-wrap:wrap;gap:8px;justify-content:center}svg{background:rgba(255,255,255,.06);border-radius:12px}
            </style><script src="https://cdn.jsdelivr.net/npm/hanzi-writer@3.5.0/dist/hanzi-writer.min.js"></script></head>
            <body><div class="row" id="row"></div><p id="msg"></p><script>
            if (typeof HanziWriter === 'undefined') { document.getElementById('msg').textContent = 'Stroke order needs an internet connection.'; }
            else { [\(list)].forEach(function (ch) {
              var el = document.createElement('div'); document.getElementById('row').appendChild(el);
              var w = HanziWriter.create(el, ch, {width: 96, height: 96, padding: 6, strokeColor: '#e8e8e8', outlineColor: '#444',
                onLoadCharDataError: function () { document.getElementById('msg').textContent = 'Stroke data could not be loaded.'; }});
              (function loop() { w.animateCharacter({onComplete: function () { setTimeout(loop, 1200); }}); })();
            }); }
            </script></body></html>
            """
        guard context.coordinator.last != html else { return }
        context.coordinator.last = html
        view.loadHTMLString(html, baseURL: URL(string: "https://cdn.jsdelivr.net/"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator { var last = "" }
}
