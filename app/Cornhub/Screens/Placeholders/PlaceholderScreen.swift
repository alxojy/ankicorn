import SwiftUI

/// Shared designed empty state for tabs whose real content lands in later phases.
struct PlaceholderScreen: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.largeTitle)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 72, height: 72)
                    .background(Theme.raised, in: Circle())
                    .accessibilityHidden(true)
                Text(title)
                    .font(.inkAnswer)
                    .foregroundStyle(Theme.text)
                Text(message)
                    .font(.body)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("placeholder-\(title.lowercased())")
        }
    }
}

#Preview("Default") {
    PlaceholderScreen(title: "Browse", symbol: "magnifyingglass", message: "Search your cards here soon.")
}

#Preview("Large text") {
    PlaceholderScreen(title: "Browse", symbol: "magnifyingglass", message: "Search your cards here soon.")
        .dynamicTypeSize(.accessibility3)
}
