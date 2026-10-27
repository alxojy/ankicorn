# Proposal

## Why

The Phase 0 app shows an unstyled deck list. PLAN.md fixes the "Ink" look (dark, orange accent). Every later screen needs the tokens, fonts and navigation shell first.

## What Changes

- Add `Theme.swift` and asset-catalog colours for every Ink token, Space Grotesk 600 (SIL OFL, with OFL.txt) and Dynamic Type scaling helpers.
- Force dark mode.
- Add the app shell: a floating dark-glass tab bar with Decks, Browse, Stats, Settings; selected tab in accent on an accent-tinted pill.
- Browse, Stats and Settings are placeholder screens with a designed empty state. The Phase 0 deck tree moves into the Decks tab.

Out of scope: the real Decks, Browse, Stats and Settings content.

## Capabilities

### Modified Capabilities
- `app-shell`: Ink theme, forced dark mode and the tab shell.

## Impact

PLAN.md Design standards (colour, type, shape, navigation). New files under `app/Cornhub/Theme/`, `app/Cornhub/Screens/`, `app/Cornhub/Resources/`.
