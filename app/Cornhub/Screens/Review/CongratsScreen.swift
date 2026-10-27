import SwiftUI

/// Shown when the queue is empty, from `congrats_info`.
struct CongratsScreen: View {
    let info: Anki_Scheduler_CongratsInfoResponse?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle).imageScale(.large).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("All done for now").font(.inkTitle).foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            if let detail { Text(detail).foregroundStyle(Theme.text2).multilineTextAlignment(.center) }
            Spacer()
            Button(action: onDone) {
                Text("Back to decks").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Theme.accent)
            .foregroundStyle(Theme.onAccent)
            .accessibilityIdentifier("congrats-done")
        }
        .padding(24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("congrats")
    }

    private var detail: String? {
        guard let info else { return nil }
        var lines: [String] = []
        if info.learnRemaining > 0 {
            let minutes = max(1, Int((Double(info.secsUntilNextLearn) / 60).rounded(.up)))
            lines.append("\(info.learnRemaining) learning cards come back in \(minutes) min.")
        }
        if info.haveSchedBuried || info.haveUserBuried { lines.append("Some cards are buried until tomorrow.") }
        return lines.isEmpty ? "You have finished today's cards." : lines.joined(separator: "\n")
    }
}

#Preview { CongratsScreen(info: nil, onDone: {}) }
