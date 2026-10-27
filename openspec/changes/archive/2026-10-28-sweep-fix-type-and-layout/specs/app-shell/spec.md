## ADDED Requirements

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
