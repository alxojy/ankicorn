import Foundation

/// How a note type's own CSS decides the look of a card: its `.card` background, if any, picks the default text.
enum CardStyle: Equatable {
    /// The note sets no opaque background: the Ink look (light text on the dark card).
    case ink
    /// The note sets an opaque light background; default text must be dark, as on desktop.
    case light(background: String)
    /// The note sets an opaque dark background; the Ink light text reads fine on it.
    case dark(background: String)

    private static let blockPattern = try? NSRegularExpression(
        pattern: #"([^{}]+)\{([^}]*)\}"#, options: [])
    private static let backgroundPattern = try? NSRegularExpression(
        pattern: #"(?<![\w-])background(?:-color)?\s*:\s*([^;}]+)"#, options: [.caseInsensitive])

    /// Reads the last plain `.card { background… }` declaration of `css`.
    static func decide(css rawCSS: String) -> CardStyle {
        let css = strippingComments(rawCSS)
        var found: String?
        let whole = NSRange(css.startIndex..., in: css)
        for block in blockPattern?.matches(in: css, range: whole) ?? [] {
            guard let selector = Range(block.range(at: 1), in: css), let body = Range(block.range(at: 2), in: css),
                css[selector].split(separator: ",").contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == ".card" })
            else { continue }
            let text = String(css[body])
            let inner = NSRange(text.startIndex..., in: text)
            for match in backgroundPattern?.matches(in: text, range: inner) ?? [] {
                if let value = Range(match.range(at: 1), in: text) { found = String(text[value]) }
            }
        }
        guard let found, let color = rgb(of: found) else { return .ink }
        let hex = String(format: "#%02X%02X%02X", color.red, color.green, color.blue)
        return luminance(color) > 0.5 ? .light(background: hex) : .dark(background: hex)
    }

    /// `css` without `/* … */` comments, so a kept copy of old CSS in a comment is never read as live rules.
    static func strippingComments(_ css: String) -> String {
        css.replacingOccurrences(of: #"/\*[\s\S]*?\*/"#, with: "", options: .regularExpression)
    }

    struct RGB: Equatable {
        var red: Int, green: Int, blue: Int
    }

    /// Relative luminance (WCAG) of a colour, 0...1.
    static func luminance(_ color: RGB) -> Double {
        func channel(_ value: Int) -> Double {
            let scaled = Double(value) / 255
            return scaled <= 0.03928 ? scaled / 12.92 : pow((scaled + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)
    }

    /// WCAG contrast ratio between two colours.
    static func contrast(_ first: RGB, _ second: RGB) -> Double {
        let a = luminance(first), b = luminance(second)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private static let named: [String: RGB] = [
        "white": RGB(red: 255, green: 255, blue: 255), "black": RGB(red: 0, green: 0, blue: 0),
        "ivory": RGB(red: 255, green: 255, blue: 240), "beige": RGB(red: 245, green: 245, blue: 220),
        "linen": RGB(red: 250, green: 240, blue: 230), "lightyellow": RGB(red: 255, green: 255, blue: 224),
        "whitesmoke": RGB(red: 245, green: 245, blue: 245), "gray": RGB(red: 128, green: 128, blue: 128),
        "grey": RGB(red: 128, green: 128, blue: 128), "navy": RGB(red: 0, green: 0, blue: 128)
    ]

    /// Hex (`#rgb`, `#rrggbb`, with optional alpha digits dropped when opaque), `rgb()` and a few names.
    /// Translucent colours, gradients, images and `transparent` return nil (not an opaque background).
    static func rgb(of value: String) -> RGB? {
        var text = value.lowercased().replacingOccurrences(of: "!important", with: "")
            .trimmingCharacters(in: .whitespaces)
        if text.contains("gradient") { return nil }
        // `background: #fff url(x)` style shorthand: only the colour token matters.
        if let token = text.range(of: #"#[0-9a-f]{3,8}\b|rgba?\([^)]*\)"#, options: .regularExpression) {
            text = String(text[token])
        }
        if let known = named[text] { return known }
        if text.hasPrefix("#") {
            var digits = String(text.dropFirst())
            if digits.count == 3 { digits = digits.map { "\($0)\($0)" }.joined() }
            if digits.count == 8 {
                guard digits.hasSuffix("ff") else { return nil }
                digits = String(digits.prefix(6))
            }
            guard digits.count == 6, let number = Int(digits, radix: 16) else { return nil }
            return RGB(red: number >> 16 & 255, green: number >> 8 & 255, blue: number & 255)
        }
        if text.hasPrefix("rgb(") || text.hasPrefix("rgba(") {
            let numbers = text.drop { $0 != "(" }.dropFirst().prefix { $0 != ")" }
                .split { $0 == "," || $0 == " " || $0 == "/" }.compactMap { Double($0.replacingOccurrences(of: "%", with: "")) }
            guard numbers.count >= 3, numbers.count == 3 || numbers[3] >= 1 else { return nil }
            return RGB(red: Int(numbers[0]), green: Int(numbers[1]), blue: Int(numbers[2]))
        }
        return nil
    }
}
