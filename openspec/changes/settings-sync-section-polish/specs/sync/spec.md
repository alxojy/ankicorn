## ADDED Requirements

### Requirement: Sync settings only when signed in
Settings SHALL show the Sync section (Sync now, sync toggles, last-synced or progress text) only when the user is signed in to AnkiWeb, and SHALL NOT show a separate "Status" row.

#### Scenario: Signed out
- **WHEN** the user opens Settings while signed out
- **THEN** the account section shows "Log in to AnkiWeb" with an explanatory footer, and there is no Sync section and no "Not signed in" status row

#### Scenario: Signed in
- **WHEN** the user is signed in
- **THEN** the Sync section shows "Sync now" with the last-synced time (or live progress while syncing), plus the Sync media and Sync on open toggles

### Requirement: Uniform Settings row heights
Rows in Settings SHALL use the standard list row height; buttons SHALL NOT add extra height.

#### Scenario: Sync now row
- **WHEN** Settings shows "Sync now" next to toggle rows
- **THEN** the row is the same height as the toggle rows
