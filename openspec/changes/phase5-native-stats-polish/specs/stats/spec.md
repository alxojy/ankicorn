## ADDED Requirements

### Requirement: Native stats tab
The Stats tab SHALL show true retention, a 16-week review heatmap and a 7-day due forecast for a chosen deck and range, using the engine's `graphs` method, and SHALL link to Anki's graphs page as "More stats".

#### Scenario: Choose a range
- **WHEN** the user selects Month
- **THEN** the retention hero shows the engine's true retention for the month

#### Scenario: No reviews yet
- **WHEN** the collection has no reviews
- **THEN** the tab shows an empty state instead of zeros

### Requirement: App icon
The app SHALL ship an opaque 1024 pt icon made from the supplied artwork without Anki branding.

#### Scenario: Reproducible
- **WHEN** scripts/make-app-icon.py runs
- **THEN** it rewrites the AppIcon image from design/app-icon-source.png
