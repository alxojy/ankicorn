## ADDED Requirements

### Requirement: Overview counts match the tile
The deck overview SHALL show the new, learning and review counts of the deck's `deck_tree` node, so they match the home tile.

#### Scenario: Sample deck
- **WHEN** the user opens HSK 1, whose tile shows 45 new
- **THEN** the overview shows 45 new, 0 learning and 0 review

### Requirement: Hero summary line
The hero line under the due count SHALL read "≈ N min · X done today · streak —", where X comes from the engine. The engine's raw sentence SHALL NOT be shown.

#### Scenario: Nothing studied yet
- **WHEN** no cards have been studied today
- **THEN** the line shows "0 done today"
