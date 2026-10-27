## ADDED Requirements

### Requirement: Ink theme tokens
The app SHALL define every Ink colour token from PLAN.md as an asset-catalog colour and expose it through `Theme.swift`; views SHALL NOT use raw hex values or fixed font sizes.

#### Scenario: Display font scales
- **WHEN** the user picks a larger Dynamic Type size
- **THEN** text set in the Space Grotesk display font grows with it

### Requirement: Dark only
The app SHALL always render in dark mode regardless of the system setting.

#### Scenario: System in light mode
- **WHEN** the device is set to light appearance
- **THEN** the app still renders with the Ink dark palette

### Requirement: Floating tab shell
The app SHALL show a floating dark-glass tab bar with Decks, Browse, Stats and Settings, where the selected tab uses the accent colour on an accent-tinted pill, every item has a VoiceOver label and a 44 pt minimum target.

#### Scenario: Switching tabs
- **WHEN** the user taps Stats
- **THEN** the Stats screen is shown and the Stats item is marked selected

#### Scenario: Placeholder screens
- **WHEN** the user opens Browse, Stats or Settings
- **THEN** a designed empty state with an SF Symbol and short text is shown

#### Scenario: Deck tree in Decks tab
- **WHEN** the app launches
- **THEN** the Decks tab is selected and shows the engine deck tree
