## Why
PLAN.md Phase 4 still lacks CSV import, export, database and media tools, and the remaining review and display preferences.

## What Changes
- Native CSV/text import using `get_csv_metadata` and `import_csv`.
- Export to `.apkg`, `.colpkg` and note/card CSV with the share sheet.
- Settings tools: check database, check media, empty cards, trash and restore media.
- More preferences: review time limit and editing/display options.

## Impact
Settings gets Import/Export and Tools screens; `Backend+Tools.swift` wraps the engine methods.
