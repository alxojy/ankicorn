## Mockup values ("Ink-Decks" artboard, 390×844 points)

The mockup is private to the user's account, so here are its values. Colours are given as Ink tokens; fonts as "display" (Space Grotesk 600 unless noted) or "body" (system).

### Screen
- `bg` background. Content padding: 58 top (under the status bar), 20 left and right. Vertical stack, 20 pt gap between sections.

### Header row (space-between, centre-aligned)
- Left column, 2 pt gap:
  - date "Tuesday, 27 Oct": body 15, weight 500, `text2` (a short month is fine);
  - status line: body 12, `muted`, preceded by a 6×6 dot (`synced` when signed in and synced, `zero` grey otherwise), 6 pt gap.
- Right: two buttons, 10 pt gap. Each is 44×44, a circle, `control` fill, a 1 pt `hairline` border, a 20 pt `text` icon (`arrow.triangle.2.circlepath`, `plus`).

### Hero (6 pt gap)
- Row, baseline-aligned, 10 pt gap: due count display 96 (line height 96, letter spacing −4); "cards due" display weight 500, 24, `muted`.
- Subline: body 15, `muted`: "About 18 min · 86 done today · 14-day streak".

### Due bar (8 pt gap)
- Bar: height 8, segments 4 pt apart, radius 4, widths proportional to new / learning / review, coloured `new`, `learning`, `accent`.
- Legend: 16 pt between items; each item is an 8×8 dot plus "35 new" (body 13, weight 500, `text2`), 6 pt gap.

### Start review
- Height 60, fully rounded, `accent` fill, `onAccent` text: "Start review", 18 bold, then an arrow-right icon (20 pt, heavy stroke), 10 pt gap.

### Decks section (4 pt extra top margin, 12 pt gap)
- Heading "Decks": display 22.
- Grid: 2 equal columns, 12 pt gaps.
- Tile: `surface`, 1 pt border at white 6%, radius 22, padding 16, column with 10 pt gaps, min height 132.
  - Glyph: 28 pt, line height 32, bold, PingFang SC. Colour by position: `new`, `learning`, `synced`, `again`, then repeat. (The mockup's fourth is a pink close to `again`.)
  - Name: 15 semibold `text`; sub line 12 `muted` ("150 words"; the app says "N cards"), 2 pt gap.
  - Counts row: display 15, tabular figures, 12 pt gap, colours `new`, `learning`, `accent`, with zeros in `zero`.
  - Progress: 4 pt tall, radius 2, `raised` track (#2A2A32), `accent` fill at the deck's progress.

### Tab bar
- Absolute position, 20 pt from the left and right, 28 pt from the bottom; height 64, radius 32; dark glass (`control` at 78% plus blur), 1 pt `hairline` border, shadow 0 10 40 black at 50%; 6 pt inner padding; 4 equal columns.
- Item: 24 pt icon over a 10 pt label, 2 pt gap. The selected item is accent icon and label, weight 600, on a pill of accent at 14% (radius 26). Others are `text2`, weight 500.
