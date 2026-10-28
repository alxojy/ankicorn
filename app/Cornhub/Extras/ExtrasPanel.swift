import SwiftUI
import Translation

/// Speak, Translate, Explain and Stroke order chips and the panel they open.
struct ExtrasChips: View {
    @Bindable var extras: ExtrasModel

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("Explain", "sparkles", filled: true, id: "chip-explain") { extras.explain() }
                    chip("Speak", "speaker.wave.2", id: "chip-speak") { extras.speak() }
                    chip("Translate", "character.bubble", id: "chip-translate") { extras.translate() }
                    if !extras.hanzi.isEmpty {
                        chip("Stroke order", "scribble", id: "chip-strokes") { extras.showStrokes() }
                    }
                }
            }
            if extras.panel != .none { panel }
        }
        .translationTask(extras.translationConfig) { session in
            let source = extras.textToTranslate
            let text = await Self.translate(source, session: UncheckedSession(session))
            extras.finishTranslation(text)
        }
    }

    /// `TranslationSession` is handed to a main-actor closure but its `translate` is nonisolated; the session is only
    /// used here, so the transfer is safe.
    private struct UncheckedSession: @unchecked Sendable { let value: TranslationSession
        init(_ value: TranslationSession) { self.value = value }
    }

    private nonisolated static func translate(_ text: String, session: UncheckedSession) async -> String? {
        try? await session.value.translate(text).targetText
    }

    private func chip(_ title: String, _ symbol: String, filled: Bool = false, id: String, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.minTarget)
                .foregroundStyle(filled ? Theme.onAccent : Theme.text)
                .background(filled ? Theme.accent : Theme.control, in: Capsule())
        }
        .accessibilityIdentifier(id)
    }

    @ViewBuilder private var panel: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch extras.panel {
            case .none: EmptyView()
            case .explanation(let text): labelled("Explanation", text)
            case .translation(let text): labelled("Translation", text)
            case .message(let text):
                Label(text, systemImage: "info.circle").font(.subheadline).foregroundStyle(Theme.muted)
            case .loading(let text):
                HStack { ProgressView(); Text(text).font(.subheadline).foregroundStyle(Theme.text2) }
            case .strokes(let chars):
                Text("Stroke order").inkLabel().foregroundStyle(Theme.accent)
                StrokeOrderView(characters: chars).frame(height: 120)
                Text("hanzi-writer (MIT), Make Me a Hanzi data (Arphic Public License)")
                    .font(.caption2).foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .accessibilityIdentifier("extras-panel")
    }

    private func labelled(_ title: String, _ text: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).inkLabel().foregroundStyle(Theme.accent)
                Text(text).font(.subheadline).foregroundStyle(Theme.text).textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 160)
    }
}
