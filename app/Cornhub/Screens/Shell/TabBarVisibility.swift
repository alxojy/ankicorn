import SwiftUI

/// Everything that can hide the floating tab bar, combined in one place.
struct TabBarVisibility: Equatable {
    /// Scroll distance (pt) before a direction change toggles the bar.
    static let threshold: CGFloat = 12

    var selectionMode = false
    var keyboardUp = false
    var voiceOverRunning = false
    private(set) var scrollMinimized = false
    private var anchor: CGFloat = 0

    var hidden: Bool { selectionMode || keyboardUp || scrollMinimized }

    /// Feed the current scroll offset and the largest reachable offset of the scroll view.
    mutating func scrolled(offset: CGFloat, maxOffset: CGFloat) {
        guard !voiceOverRunning else { reset(); return }
        // Top, bottom (or content that fits) always show the bar.
        if offset <= 0 || maxOffset <= 0 || offset >= maxOffset - 1 {
            scrollMinimized = false
            anchor = max(offset, 0)
            return
        }
        if scrollMinimized {
            if offset > anchor { anchor = offset } else if anchor - offset > Self.threshold {
                scrollMinimized = false
                anchor = offset
            }
        } else if offset < anchor {
            anchor = offset
        } else if offset - anchor > Self.threshold {
            scrollMinimized = true
            anchor = offset
        }
    }

    /// Navigating or switching tabs shows the bar again.
    mutating func reset() {
        scrollMinimized = false
        anchor = 0
    }
}

private struct ScrollMetrics: Equatable {
    var offset: CGFloat
    var maxOffset: CGFloat
}

private struct TabBarScroll: ViewModifier {
    @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
            .onScrollGeometryChange(for: ScrollMetrics.self) { geo in
                ScrollMetrics(
                    offset: geo.contentOffset.y + geo.contentInsets.top,
                    maxOffset: geo.contentSize.height - geo.containerSize.height
                        + geo.contentInsets.top + geo.contentInsets.bottom)
            } action: { _, metrics in
                appState.visibility.scrolled(offset: metrics.offset, maxOffset: metrics.maxOffset)
            }
            .onDisappear { appState.visibility.reset() }
    }
}

extension View {
    /// Reports scrolling to the shell so the tab bar can minimize, and keeps the last row above the bar.
    func tabBarScroll() -> some View { modifier(TabBarScroll()) }
}
