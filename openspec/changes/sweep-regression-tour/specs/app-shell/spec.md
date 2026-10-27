## ADDED Requirements

### Requirement: Screen tour regression suite
The UI test suite SHALL include a screen tour on the seeded sample collection. It SHALL visit the home, deck overview, deck options, review (question, answer, grade, swipe, menu, undo), add card, browse, stats, settings (manage, tools, import/export, login) and the largest text size, attach a screenshot per state and assert a visible result on each.

#### Scenario: Full gate
- **WHEN** `ANKICORN_FULL=1 npm run gate` runs
- **THEN** the screen tour passes
