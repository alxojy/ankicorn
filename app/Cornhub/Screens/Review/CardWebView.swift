import SwiftUI
import WebKit

/// Renders a card's HTML in a transparent, non-interactive WKWebView over the base Ink stylesheet.
struct CardWebView: UIViewRepresentable {
    let html: String
    let css: String

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
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
        view.loadHTMLString(document, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var last = ""
    }

    static func document(body: String, css: String) -> String {
        """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <style>\(baseCSS)\n\(css)</style></head><body><div class="card">\(body)</div></body></html>
        """
    }

    /// Ink look for card bodies; colours are resolved from the theme tokens.
    static var baseCSS: String {
        """
        html, body { margin: 0; background: transparent; }
        body { color: \(hex(Theme.text)); font: -apple-system-body; font-size: 20px; text-align: center;
               display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .card { width: 100%; padding: 8px; box-sizing: border-box; color: \(hex(Theme.text)); }
        hr { border: 0; border-top: 1px solid \(hex(Theme.muted)); opacity: 0.4; margin: 16px 0; }
        b, strong { color: \(hex(Theme.accent)); }
        img { max-width: 100%; border-radius: 20px; }
        """
    }

    private static func hex(_ color: Color) -> String {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
