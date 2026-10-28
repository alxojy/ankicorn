## 1. Settings
- [x] 1.1 No extra `minHeight` frames on List row buttons; Settings rows have equal standard heights
- [x] 1.2 Signed out: no Sync section and no Status row; the account footer explains sync
- [x] 1.3 Signed in: Sync now with last-synced, progress or error text in place; no separate Status row; toggles only when signed in

## 2. Proof
- [ ] 2.1 `ScreenTourUITests` `testSettings` and `testLoginRefreshesSettings` pass. Assert no "Status" row and no "Sync now" while signed out, and "Sync now" plus the toggles after the stubbed login. Also assert that the frame heights of "Sync now", "Log out" and "Back up now" each differ from the "Sync media" toggle row by under 4 pt (all `minHeight` button rows in `SettingsScreen` are affected, not only Sync now)
- [ ] 2.2 Review the signed-out and signed-in Settings screenshots: rows look even and match the Ink look
