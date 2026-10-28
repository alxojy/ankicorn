import SwiftUI

/// Dark-glass capsule tab bar. The selected tab is accent on an accent-tinted pill.
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                            .frame(height: 28)
                        Text(tab.title)
                            .font(.caption2.weight(selected ? .semibold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selected ? Theme.accent : Theme.text2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selected {
                            Capsule().fill(Theme.accent.opacity(0.14))
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityShowsLargeContentViewer {
                    Label(tab.title, systemImage: tab.symbol)
                }
                .accessibilityAddTraits(selected ? [.isSelected] : [])
                .accessibilityIdentifier("tab-\(tab.rawValue)")
            }
        }
        .padding(6)
        .frame(height: Theme.tabBarHeight)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .glassEffect(.regular.tint(Theme.bg.opacity(0.6)), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
        .padding(.horizontal, Theme.margin)
        .padding(.bottom, Theme.tabBarBottomInset)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    FloatingTabBar(selection: .constant(.decks))
        .padding(.vertical)
        .background(Theme.bg)
}
