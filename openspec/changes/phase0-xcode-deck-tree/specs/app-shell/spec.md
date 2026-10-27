## ADDED Requirements

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
