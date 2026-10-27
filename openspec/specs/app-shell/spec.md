# app-shell Specification

## Purpose
The Cornhub iOS app target: it builds for iOS 26 in Swift 6, links the bridge XCFramework, launches in the simulator, and shows the deck tree the engine returns, with accessible labels and Dynamic Type.

## Requirements

### Requirement: App builds and launches
The Cornhub app target SHALL build for iOS 26 or later in Swift 6 language mode, link the bridge XCFramework, and launch in the iOS simulator.

#### Scenario: Simulator launch
- **WHEN** the app is launched on the `iPhone 17` simulator
- **THEN** it reaches its first screen without crashing

### Requirement: Engine deck tree on screen
The first screen SHALL open the collection in the app's Documents folder through the engine and list the deck tree returned by `deck_tree`, using the names and nesting from the engine's response.

#### Scenario: Seeded sample decks
- **WHEN** the app is launched with the `--seed-sample` argument on an empty collection
- **THEN** it creates the decks "HSK 1", "HSK 2" and "HSK 2::Verbs" through the engine and shows them with their nesting

#### Scenario: Engine error is shown
- **WHEN** opening the collection fails
- **THEN** the screen shows the engine's error message instead of crashing

### Requirement: Accessible labels
Every row of the deck tree SHALL have a VoiceOver label containing the deck name, and text SHALL scale with Dynamic Type.

#### Scenario: Large text
- **WHEN** the UI test runs at the largest accessibility text size
- **THEN** deck names remain visible and are not truncated to nothing

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

### Requirement: Display font resolves
The Space Grotesk 600 display font SHALL load at runtime and be used wherever the design standard calls for the display face. Silently falling back to the system font is not acceptable.

#### Scenario: Due count
- **WHEN** the Decks tab shows the due count
- **THEN** it renders in Space Grotesk SemiBold

### Requirement: Tab bar at large text sizes
The floating tab bar labels SHALL never wrap or break words at any Dynamic Type size, and the bar SHALL stay within the bottom fifth of the screen.

#### Scenario: Largest accessibility size
- **WHEN** the text size is AX XXXL
- **THEN** each tab shows its icon and its label on one line, or icon only with the large-content viewer

### Requirement: Display face usage
Big numbers, screen titles, count rows, the English answer on cards and the grade stamp SHALL use the Space Grotesk display face, scaled with Dynamic Type.

#### Scenario: Home hero
- **WHEN** the Decks tab shows "45 cards due"
- **THEN** the number and the deck tile counts render in Space Grotesk

### Requirement: Floating grade bar
The review grade bar SHALL float above the content as a dark glass capsule with a hairline border, matching the tab bar, and the next card SHALL peek out behind the current card.

#### Scenario: Answer side
- **WHEN** the answer is revealed
- **THEN** the four grade buttons sit in a glass capsule, and the edge of the next card is visible behind the current one
