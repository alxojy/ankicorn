## ADDED Requirements

### Requirement: Tab bar below the keyboard
The floating tab bar SHALL NOT appear above the software keyboard. While the keyboard is showing, the tab bar SHALL be hidden or stay at the bottom edge behind it, and it SHALL return when the keyboard closes.

#### Scenario: Searching in Browse
- **WHEN** the user focuses the Browse search field and the keyboard appears
- **THEN** the tab bar is not shown above the keyboard

#### Scenario: Keyboard closes
- **WHEN** the keyboard is dismissed
- **THEN** the tab bar is visible and tappable again
