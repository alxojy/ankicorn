import SwiftUI

/// Dark-glass capsule tab bar. The selected tab is accent on an accent-tinted pill.
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.symbol)
                            .font(.body)
                        Text(tab.title)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(selected ? Theme.accent : Theme.text2)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                    .padding(.vertical, 6)
                    .background {
                        if selected {
                            Capsule().fill(Theme.accent.opacity(0.16))
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityIdentifier("tab-\(tab.rawValue)")
            }
        }
        .padding(6)
        .glassEffect(.regular.tint(Theme.bg.opacity(0.6)), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
        .padding(.horizontal, 16)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    FloatingTabBar(selection: .constant(.decks))
        .padding(.vertical)
        .background(Theme.bg)
}
