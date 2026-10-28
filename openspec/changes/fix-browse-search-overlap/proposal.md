## Why
On the user's iPhone, the Browse tab's "Search cards" field sits underneath the floating tab bar, and the two overlap.

Cause: `BrowseScreen` uses `.searchable(text:prompt:)` with no placement. On iOS 26 iPhone, that puts the search field in a bottom bar. Our tab bar isn't the system tab bar; it's a custom `FloatingTabBar` overlay drawn by `AppShell`. So the system doesn't know to lift the search field above it.

## What Changes
- Browse search moves to the top, under the title: `.searchable(text:placement: .navigationBarDrawer(displayMode: .always), prompt: "Search cards")`. It stays visible above the Cards/Notes switch, styled with Ink tokens (the control background, `muted` placeholder).
- Search behaviour is unchanged (engine `search_cards`, the same debounce and filter chips).
- Audit every screen inside the tab shell for other system bars or controls placed at the bottom (bottom toolbars, `.searchable` without a placement, `safeAreaInset(edge: .bottom)`), and make sure nothing sits under the floating tab bar. Lists keep `Theme.tabBarClearance`.

## Impact
`app/Cornhub/Screens/Browse/BrowseScreen.swift` (and any screen the audit finds), plus `ScreenTourUITests.testBrowse`.
