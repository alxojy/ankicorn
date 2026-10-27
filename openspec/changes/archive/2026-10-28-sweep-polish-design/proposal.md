## Why
After the functional fixes, the sweep screenshots still differ from the PLAN.md "Design standards" (Ink, look B) in a few places, and one build setting is fragile:
- Space Grotesk now loads, but most display text still uses SF Pro. The design standard uses the display face for big numbers (due count, retention), screen titles, the English answer on cards, count rows (deck tile counts, overview counts, the review progress counts) and the grade stamp.
- Review: the mockup has the next card peeking out behind the current one, and the grade bar floating as a dark glass capsule (`.glassEffect` or `.ultraThinMaterial`, hairline border, deep shadow), like the tab bar.
- Add card with the keyboard up: the Auto-fill button is clipped at the scroll edge above Add card.
- Browse rows run the note's fields together ("你好nǐ hǎo hello 你好，我叫小明…"). The secondary line should be the answer column text with field separators collapsed to " · ", truncated to one line.
- Find duplicates groups notes in Swift on the first field. Use the engine instead: search `dupe:<notetypeId>,<text>` through `search_notes`, or the engine's duplicate finding, so no matching logic sits in Swift (CLAUDE.md rule 6).
- Build: the XCFramework has only arm64 slices. `xcodebuild` and Xcode can fail with "There is no XCFramework found" when the simulator build also targets x86_64. Exclude x86_64 for the simulator SDK in `app/project.yml` (`EXCLUDED_ARCHS[sdk=iphonesimulator*]: x86_64`) and regenerate the project.

## What Changes
The items above, each kept small. Ink tokens only, Dynamic Type preserved.

## Impact
`Theme`, `Screens/DeckHome`, `Screens/Review`, `Screens/NoteEditor`, `Screens/Browse`, `Screens/Manage` (duplicates), `app/project.yml`, `app/Cornhub.xcodeproj`.
