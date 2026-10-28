## Why
The user compared the Decks (home) tab on their iPhone with the Ink mockup ("Ink-Decks" artboard) and it looks different. Sizes, spacing and grouping drift from the mockup, and the streak never shows. `design.md` lists the mockup's exact values; it is the source of truth for this change, together with PLAN.md "Decks (home tab)".

## What Changes
- **Header:** a small date (body 15, medium, `text2`) with the sync status under it (caption 12, `muted`, with a 6 pt status dot). On the right, exactly two 44 pt round buttons, Sync and Add card, on `control` with a `hairline` border. The Import button leaves the header: importing `.apkg`/`.colpkg` moves to Settings › Import and export, as an "Import deck" row there, and its footer copy is updated. The empty-state "Import deck" button stays.
- **Hero:** the due count (display 96) and "cards due" (display 24, weight 500, `muted`) on **one baseline-aligned row**, then the subline "About N min · X done today · N-day streak" (15, `muted`). The streak comes from the same engine-backed value as the Stats tab (`StatsModel.streak` or a shared helper); it shows "No streak yet" when it is 0.
- **Due bar:** an 8 pt bar split into new / learning / review segments (flex by count, 4 pt gaps, 4 pt radius). At 0 due it shows one empty `raised` track. The legend under it reads count first, lower case: "35 new · 6 learning · 91 review" (13, weight 500, `text2`, 8 pt dots).
- **Start review:** a 60 pt pill, accent fill, 18 pt bold `onAccent` text and a trailing `arrow.right` symbol.
- **Spacing:** sections sit 20 pt apart, 20 pt side margins; no extra gaps.
- **"Decks" heading:** display 22 (not the large title).
- **Deck tiles** (2-column grid, 12 pt gaps): `surface` with a `hairline` border, radius 22, padding 16, min height about 132. Contents, 10 pt apart:
  - glyph: 28 pt bold in PingFang SC (system font for Latin), coloured by tile position, cycling `new`, `learning`, `synced`, `again`;
  - name: 15 semibold;
  - sub line: 12 `muted`, "N cards";
  - counts: display 15, tabular, coloured, zeros in `zero`;
  - progress bar: 4 pt, `raised` track and accent fill.
- **Tab bar:** a 64 pt capsule, 20 pt side inset, 28 pt above the bottom safe edge, 10 pt labels, 24 pt icons. The selected tab keeps the accent-tinted pill.
- All sizes are relative to Dynamic Type (`relativeTo:`); the accessibility-size behaviour from sweep-fix-xxxl-review stays.

## Impact
`Screens/DeckHome/DeckHomeScreen.swift`, `DeckTileView.swift` / `DeckTile.swift`, `Screens/Shell/FloatingTabBar.swift`, `Screens/Settings/ImportExportScreen.swift`, maybe `Theme.swift` (tokens only), and `ScreenTourUITests` (the import button moves).
