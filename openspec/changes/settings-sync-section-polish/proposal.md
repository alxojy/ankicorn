## Why
User feedback on Settings:
- **"Sync now" is taller than the other rows.** In `SettingsScreen.syncSection` the button has `.frame(minHeight: Theme.minTarget)`, and so do "Log in to AnkiWeb", "Log out" and "Back up now". A `List` row is already at least 44 pt, so the extra frame adds height on top of the row's own padding, and these rows come out taller than the toggles and labelled rows around them.
- **"Status: Not signed in" is redundant.** When signed out, the Sync section still shows its toggles, a disabled "Sync now" and a Status row that repeats what the "Log in to AnkiWeb" button above already says.

## What Changes
- **Standard row heights:** remove the extra `.frame(minHeight:)` from buttons inside Settings `List` rows (all sections: account, sync, backups, and any others with the same pattern). Rows get the system list height, which already meets the 44 pt target. Check with the largest Dynamic Type size that targets still meet 44 pt.
- **Signed out:** hide the Sync section entirely (no toggles, no Sync now, no Status). The account section shows only "Log in to AnkiWeb", with a footer: "Sync your collection with desktop Anki through AnkiWeb."
- **Signed in:** the Sync section shows "Sync now", and the last-synced time as the button row's trailing secondary text or as the section footer ("Last synced 2 min ago"). During a sync it shows the live progress text in place of the time, and "Sync now" is disabled with a small progress indicator. Remove the separate "Status" row. After a failure, show the error in red (`again`) in the footer until the next sync.
- The "Sync media" and "Sync when the app opens" toggles appear only when signed in.

## Impact
`app/Cornhub/Screens/Settings/SettingsScreen.swift`, maybe `SyncModel.swift` (a `lastSyncedText` without the signed-out case), and `ScreenTourUITests` (`testSettings`, `testLoginRefreshesSettings`).
