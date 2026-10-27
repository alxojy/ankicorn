## Why
PLAN.md (Phase 3 and "Design standards") says the hosted Anki web pages get an Ink CSS override. In the final sweep, `AnkiWebView.inkCSS` sets Anki's colour variables, but it doesn't reach every control:
- Deck options: the Save button is blue, the preset tabs have a blue underline, the switches are grey Bootstrap discs, and the preset dropdown uses the system look.
- More stats: the radio buttons are blue.
- Headings use the system font, not the Ink display font.

## What Changes
- Find the selectors and variables that Anki 26.09.3 actually uses for these controls (`third_party/anki/ts/lib/sass/`, `ts/routes/deck-options`, `ts/routes/graphs`, Bootstrap's `.btn-primary`, `.form-check-input`, `.form-switch` and `--bs-*` variables). Extend the override so they use the Ink tokens:
  - primary buttons accent fill with dark text;
  - checked radios, checkboxes and switches use the accent;
  - the selected tab underline uses the accent;
  - selects use the control background.
- Headings (`h1`, `h2`, the section titles) use the Ink display font if it can be loaded in the page (`cornhub://` font route or `@font-face` from the bundle); otherwise the system rounded font.
- Override only colours, fonts and radii. No layout changes, and no edits to Anki's built pages: CSS injection only.

## Impact
`app/Cornhub/Web/AnkiWebView.swift`, plus `AnkiWebScheme.swift` if a font route is needed.
