import SwiftUI

/// Ink design tokens (PLAN.md "Design standards"). Views use only these; no raw hex, no fixed font sizes.
enum Theme {
    static let bg = Color("InkBg")
    static let surface = Color("InkSurface")
    static let card = Color("InkCard")
    static let control = Color("InkControl")
    static let raised = Color("InkRaised")
    static let raisedHigh = Color("InkRaisedHigh")
    static let hairline = Color.white.opacity(0.08)
    static let text = Color("InkText")
    static let text2 = Color("InkText2")
    static let muted = Color("InkMuted")
    static let zero = Color("InkZero")
    static let accent = Color("InkAccent")
    static let onAccent = Color("InkOnAccent")
    static let new = Color("InkNew")
    static let learning = Color("InkLearning")
    static let again = Color("InkAgain")
    static let easy = Color("InkEasy")
    static let synced = Color("InkSynced")
    /// Review heatmap, none to most.
    static let heatmap = [Color("InkHeat0"), Color("InkHeat1"), Color("InkHeat2"), Color("InkHeat3"), Color("InkHeat4")]

    enum Radius {
        static let reviewCard: CGFloat = 30
        static let panel: CGFloat = 24
        static let tile: CGFloat = 22
        static let photo: CGFloat = 20
    }

    /// Minimum touch target.
    static let minTarget: CGFloat = 44
}

/// Pt sizes at default Dynamic Type from PLAN.md. They are base sizes that scale; never used as fixed sizes.
enum DisplaySize {
    static let dueCount: CGFloat = 96
    static let retention: CGFloat = 72
    static let hanzi: CGFloat = 60
    static let hanziField: CGFloat = 44
    static let title: CGFloat = 34
    static let answer: CGFloat = 28
}

extension Font {
    /// Space Grotesk 600, scaled with Dynamic Type relative to `style`.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        // Static SemiBold instance cut from the variable Space Grotesk (the variable file's default
        // instance is Light and has no SemiBold PostScript name, so it silently fell back to SF Pro).
        .custom(FontRegistration.displayFontName, size: size, relativeTo: style)
    }

    static var inkTitle: Font { display(DisplaySize.title, relativeTo: .largeTitle) }
    static var inkAnswer: Font { display(DisplaySize.answer, relativeTo: .title) }
    /// Field labels: 12 pt caps; apply `.inkLabel()` for the letter spacing.
    static var inkLabel: Font { .caption.weight(.medium) }
}

extension View {
    /// Uppercase, letter-spaced field label in `muted`.
    func inkLabel() -> some View {
        font(.inkLabel).textCase(.uppercase).tracking(0.8).foregroundStyle(Theme.muted)
    }
}
