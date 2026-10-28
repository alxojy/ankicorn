## Why
User report with a screenshot of the Mandarin (HSK) deck overview: "when I scroll down the bar blocks." While scrolling, the floating tab bar sits on top of the subdeck tiles and cuts through them (HSK1/HSK3 progress bars, HSK2/HSK4 icons), with no scrim, so content and bar clash. It is always there, taking about 70 pt of a phone screen.

What the code does now: `AppShell` draws `FloatingTabBar` in a bottom-aligned `ZStack` over every screen and pads the screen's bottom safe area so the last row can scroll clear. Nothing reacts to scrolling. `AppState.hideTabBar` exists (set by Browse selection mode) and slides the bar away.

## What Changes
- **Minimize on scroll down:** like iOS 26's own tab bars, the floating tab bar slides away when the user scrolls content down and comes back when they scroll up, reach the top, or reach the bottom of the content. Small scroll jitters (under ~12 pt) don't toggle it. Applies to every scrolling screen in the tab shell (Decks home, deck overview, Browse list, Stats, Settings). Use `onScrollGeometryChange` (or `onScrollPhaseChange`) per scroll view feeding one shared state, e.g. `AppState.tabBarMinimized`.
- **One visibility rule:** the bar is hidden when any reason holds (Browse selection mode, keyboard if `browse-live-search-keyboard` has landed, scroll-minimized). Keep these as separate inputs combined in one computed property so they don't fight. Switching tabs or pushing/popping a screen shows the bar again.
- **Bottom scrim:** behind the bar, a short gradient from `Theme.bg` to clear at the bottom edge, so content passing under the bar fades instead of clashing. Tokens only.
- **Last row reachable:** every tab screen and pushed screen (including the deck overview) can scroll its last row fully above the bar when the bar is showing. Fix any screen where the bottom padding doesn't reach a pushed view.
- Reduce Motion: the bar fades instead of sliding. VoiceOver: never minimize while VoiceOver is running.

## Impact
`Screens/Shell/AppShell.swift`, `FloatingTabBar.swift`, the scrolling screens (`DeckHomeScreen`, `DeckOverviewScreen`, `BrowseScreen`, Stats, Settings), and tests. Run after `browse-live-search-keyboard`, which also changes the tab bar's visibility in `AppShell`.
