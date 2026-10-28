## ADDED Requirements

### Requirement: No dead controls on the congrats screen
The "All done for now" screen SHALL show only header controls that do something: close always, Undo only when an answer can be undone, and ⋯ only when it has an enabled action.

#### Scenario: Nothing to undo
- **WHEN** the review opens straight to "All done for now" with nothing graded
- **THEN** the header shows only the close button

#### Scenario: Undo the last answer
- **WHEN** the user grades the last due card, sees "All done for now" and taps Undo
- **THEN** that card shows again on its question side, and the counts include it
