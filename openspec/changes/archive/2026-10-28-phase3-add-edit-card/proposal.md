## Why
Phase 3 needs creating and editing cards on the phone. PLAN.md "Screens > Add card" and the parity rows "Add cards" and "Field editor" describe one full-screen editor that also edits existing notes.

## What Changes
- A native full-screen Add card screen: deck and note-type chips with pickers (defaults from `defaults_for_adding`), fields that follow the note type, a picture tile, audio recording, tags, sticky fields and a formatting toolbar.
- `add_note` adds the note; the deck and note type stay selected for the next card.
- The same editor edits existing notes (review menu "Edit note"), replacing the plain field sheet.
- Backend wrappers: `defaults_for_adding`, `get_deck_names`, `all_tags`, `add_media_file`.
- The Decks tab "+" button opens Add card. The Auto-fill button is present but disabled until phase3-ai-extras.
- Image occlusion is not included: the web bridge does not host that page yet (noted as TODO).
