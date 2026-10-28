## ADDED Requirements

### Requirement: Tab bar minimizes on scroll
The floating tab bar SHALL slide away when the user scrolls content down and SHALL come back when they scroll up or reach the top or end of the content. Content passing under the bar SHALL fade into a bottom scrim, and the last row of any screen SHALL be able to scroll fully above the visible bar.

#### Scenario: Scrolling down a deck overview
- **WHEN** the user scrolls down the subdeck grid of a deck overview
- **THEN** the tab bar slides away and no longer covers the tiles

#### Scenario: Scrolling back up
- **WHEN** the user scrolls up, or reaches the top or the end of the content
- **THEN** the tab bar is shown and tappable again

#### Scenario: End of content
- **WHEN** the user scrolls to the end of any tab screen with the bar showing
- **THEN** the last row sits fully above the bar

#### Scenario: VoiceOver
- **WHEN** VoiceOver is running
- **THEN** the tab bar never minimizes
