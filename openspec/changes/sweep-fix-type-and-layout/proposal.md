## Why
The final sweep screenshots show three design-standard failures (PLAN.md "Type" and "Foundation"):
- The display font is not applied. The "45" due count and the titles render in SF Pro, not Space Grotesk 600. The phase1-ink-theme worker warned that the variable font's name "SpaceGrotesk-SemiBold" may not resolve.
- At the largest accessibility text size (AX XXXL), the floating tab bar labels wrap mid-word ("Bro/wse", "Set-/ting/s") and fill a third of the screen, and the home header's round buttons lose their circles and collide with the date.
- On Add card with the keyboard up, the formatting toolbar overlaps the "Add card" button and the tag chips are hidden behind it.

## What Changes
- Register and use Space Grotesk so `Theme` display fonts really resolve: check the PostScript name in the bundled TTF, and use a static SemiBold instance or a variation axis. Verify it at runtime with `UIFont(name:)`.
- Tab bar: cap the label Dynamic Type size (for example `.dynamicTypeSize(...DynamicTypeSize.xxLarge)` on the bar) so it never wraps. Accessibility sizes keep icon + label legible, with the large-content viewer (`accessibilityShowsLargeContentViewer`).
- Home header: at accessibility sizes, stack the date above the buttons; buttons keep 44 pt circles.
- Add card: put the formatting toolbar in the keyboard toolbar (or above it) and give the Add button its own safe area, so nothing overlaps. Tags stay reachable by scrolling.

## Impact
`app/Cornhub/Theme/*`, `Resources/Fonts`, `Screens/Shell/FloatingTabBar.swift`, `Screens/DeckHome/DeckHomeScreen.swift`, `Screens/NoteEditor/NoteEditorScreen.swift`.
