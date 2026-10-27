# import-export-tools Specification

## Purpose
CSV import, package and CSV export with the share sheet, maintenance tools (database, media, empty cards, media trash) and review and editing preferences.

## Requirements

### Requirement: CSV import
The app SHALL import a CSV or text file picked from Files with the engine's CSV importer and show how many notes were added or updated.

#### Scenario: Import a file
- **WHEN** the user picks a CSV file and confirms
- **THEN** the engine imports it and the result summary is shown

### Requirement: Export
The app SHALL export the collection as `.colpkg`, a deck or the collection as `.apkg`, and notes or cards as CSV, and offer the file in the share sheet.

#### Scenario: Export a package
- **WHEN** the user exports an `.apkg`
- **THEN** the engine writes the file and the share sheet offers it

### Requirement: Maintenance tools
The app SHALL offer check database, check media, empty cards cleanup, and trashing or restoring unused media from Settings.

#### Scenario: Check database
- **WHEN** the user runs Check database
- **THEN** the engine's problem report is shown

### Requirement: Review and display preferences
Settings SHALL expose the review time limit and the editing and search options from the engine's preferences.

#### Scenario: Change a preference
- **WHEN** the user toggles an editing option
- **THEN** it is saved with `set_preferences`
