## Why
User screenshot of Deck options, captioned "Default (used by 6 decks) part looks horrendous":
- **The preset field:** the name sits at the top-left and the chevron at the bottom-right, inside an over-tall box.
- **The open list:** it's a desktop-style popover with a slate-blue highlighted row and an orange left bar, and it overlaps the "Daily Limits" heading behind it.
- **Save:** the Save split button is a different height from the field.

This is Anki's own `ts/lib/components/Select.svelte` + `SelectOption.svelte` + `Popover.svelte`, as used by `ts/routes/deck-options/ConfigSelector.svelte`. `fix-deck-overview-unbury-options` added phone CSS for the header bar (`.button-bar`) but not for the select's internals or its popover, and it has not been checked on a screen yet (build-only).

The same `Select` is used by other dropdowns on the page (for example the new card gather order). Those show the same desktop look.

## What Changes
Style Anki's select and popover for the phone through the injected Ink CSS. Anki's built pages aren't edited.
- **Closed select:**
  - **Size:** one line, vertically centred text, the chevron centred on the right, 44 pt high.
  - **Look:** the Ink control background and radius 12, the same height as Save.
  - **Long names:** a long preset name truncates with "…".
- **Open list:**
  - **Container:** an Ink surface (raised), radius 14, a soft shadow, the full width of the select, and above everything else, with no overlap glitch over section headings.
  - **Rows:** 44 pt high, body text, and a ✓ in the accent colour on the selected row instead of the blue fill and left bar. A subtle Ink highlight while pressed. The list scrolls if long.
- **Section headers:** each section title ("Daily Limits", "New Cards"…) and its ? help button share one baseline row. The title is on the left in the Ink section-title size (smaller than now, not the huge display size). The ? is a 44 pt target, vertically centred on the title, with the Ink muted icon colour instead of the white filled circle. These come from `ts/lib/components/TitledContainer.svelte` (title) and the help `Badge`/`HelpModal` trigger. The hairline under the title stays.
- **Every dropdown:** the same rules apply to every `Select` on the deck options page (and on the other hosted pages that use it).
- **Save:** the split button matches the field's height, and its chevron segment has the same radius.
- **Fallback:** if CSS can't fix the popover's placement on WKWebView, replace the preset row with a native SwiftUI header above the web view: a native `Menu` of presets, plus Save. These drive the page through the bridge (Anki's page exposes its state; switching presets and saving go through the same calls `ConfigSelector` uses). Document which route was taken.

## Impact
`Web/AnkiWebView.swift` (`inkCSS`; maybe a native header and JS calls), and tests. It builds on `fix-deck-overview-unbury-options`, which is merged but whose proof hasn't run yet; the final sweep checks both.
