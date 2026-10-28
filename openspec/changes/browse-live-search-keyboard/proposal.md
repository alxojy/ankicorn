## Why
Follow-ups the `fix-browse-search-overlap` worker noticed, which the user wants fixed:
- **Search only runs on submit.** `BrowseScreen` calls `model.search()` from `.onSubmit(of: .search)`, so the list doesn't filter while typing. Clearing the field (the ⓧ button) doesn't bring the full list back either until the user submits.
- **The tab bar floats above the keyboard.** `AppShell` puts `FloatingTabBar` in a bottom-aligned `ZStack` and doesn't ignore the keyboard safe area, so when the keyboard is up the bar rides on top of it. That covers results and looks broken. It happens on every screen with a text field, not only Browse.

## What Changes
- **Live search:** Browse searches as the user types, debounced (about 300 ms after the last keystroke, cancelling the previous pending search), and still searches right away on submit. Clearing the field shows all cards again. The engine still does the search (`browserSearch`); only the trigger changes. A stale search finishing late must not overwrite newer results.
- **Tab bar hides with the keyboard:** while the software keyboard is showing, the floating tab bar is hidden (or stays behind the keyboard at the bottom edge, never above it). It comes back when the keyboard closes. Applies app-wide through `AppShell`.

## Impact
`Screens/Browse/BrowseScreen.swift`, `BrowseModel.swift`, `Screens/Shell/AppShell.swift` (and `FloatingTabBar.swift` if needed), and tests. Run after `browse-delete-and-deck-scope`, which also changes the tab bar's visibility (hidden while selecting); both rules must hold together.
