## ADDED Requirements

### Requirement: Deck screen with collection, today and coming up
Opening a deck SHALL show one screen with a header (breadcrumb to the parent, name, ⋯ menu), the collection card, today's New / Learning / Due tiles, a Study button, a Levels list only when the deck has subdecks, the 7-day forecast, and rows for Browse cards, Custom study and Daily limits & options. All counts SHALL come from the engine.

#### Scenario: Leaf deck
- **WHEN** the user opens HSK1, a subdeck of Mandarin (HSK) with no subdecks of its own
- **THEN** the header shows "Mandarin (HSK) ›" above "HSK1", the collection card shows the total with mature and young counts and when it was last studied, the Today tiles show New, Learning and Due, the Study button reads "Study HSK1 · N cards", Coming up shows tomorrow and the next 7 days, and there is no Levels list

#### Scenario: Parent deck
- **WHEN** the user opens Mandarin (HSK), which has four subdecks
- **THEN** the screen shows "Today, across all levels", a "Study all · N cards" button, and a Levels list with each subdeck's seen bar and New, Learn and Due counts; tapping a level opens its deck screen

#### Scenario: Limit holds counts back
- **WHEN** the daily review limit caps the due count
- **THEN** the Due tile says it is capped, and tapping it explains the limit and links to Daily limits & options

#### Scenario: Nothing due
- **WHEN** the deck has nothing to study today
- **THEN** the Study button reads "Nothing due today" and is disabled, with Custom study right below

#### Scenario: Breadcrumb
- **WHEN** the user taps "Mandarin (HSK) ›" on HSK1's screen
- **THEN** the Mandarin (HSK) deck screen opens
