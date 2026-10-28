## ADDED Requirements

### Requirement: Deck options header fits the phone
The hosted deck options page's preset selector and Save button SHALL fit within the screen with standard margins and equal heights, in the Ink look, without editing Anki's built pages.

#### Scenario: Default width
- **WHEN** the deck options page opens on an iPhone
- **THEN** the preset dropdown and the Save button sit inside 16 pt margins at the same height, and nothing is cut off at the edge

### Requirement: Done does not lose deck option edits
Closing the deck options page with the native Done button SHALL NOT silently discard unsaved changes.

#### Scenario: Edited then Done
- **WHEN** the user changes "New cards/day" and taps Done
- **THEN** the change is saved (or the user is asked to save or discard), and reopening the page shows the saved value
