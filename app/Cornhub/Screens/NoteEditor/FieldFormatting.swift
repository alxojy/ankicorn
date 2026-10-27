import SwiftUI

/// Wraps the selected text of a field in HTML (or cloze) markup, as the formatting toolbar does.
enum FieldFormatting {
    enum Style {
        case bold, italic, underline
        case cloze(Int)

        var markers: (String, String) {
            switch self {
            case .bold: ("<b>", "</b>")
            case .italic: ("<i>", "</i>")
            case .underline: ("<u>", "</u>")
            case .cloze(let number): ("{{c\(number)::", "}}")
            }
        }
    }

    /// Applies `style` to the selection (or at the cursor, or the whole field when nothing is selected).
    static func apply(_ style: Style, to text: inout String, selection: TextSelection?) {
        let (open, close) = style.markers
        var range = text.endIndex..<text.endIndex
        if let selection, case .selection(let selected) = selection.indices, text.indices.contains(selected.lowerBound) || selected.lowerBound == text.endIndex {
            range = selected
        }
        if range.isEmpty, !text.isEmpty, case .cloze = style { range = text.startIndex..<text.endIndex }
        text.replaceSubrange(range, with: open + text[range] + close)
    }
}
