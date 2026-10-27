## Why
Review needs the per-card actions Anki users expect, and custom study, so the menu in the Review header is more than a placeholder.

## What Changes
- Review ⋯ menu: Flag (1–7), Mark, Bury, Suspend, Edit note, Card info (stub until the web bridge in Phase 3), Redo.
- Edit note opens a simple field editor sheet (`get_note`, `update_notes`).
- Deck overview offers Custom study (common options via `custom_study_defaults`, `custom_study`) and Unbury (`unbury_deck`).
- Backend wrappers: `setFlag`, `buryOrSuspendCards`, `getNote`, `updateNotes`, `addNoteTags`, `removeNoteTags`, `customStudyDefaults`, `customStudy`, `unburyDeck`, `getCard`.

## Impact
Extends the `review` capability.
