## 1. Fix
- [x] 1.1 Sign-in state is an observed stored property on `SyncModel`, set in init, login and logout
- [x] 1.2 Settings, the Decks header status and the Sync button update right after login and logout, with no tab switch

## 2. Proof
- [x] 2.1 A unit test with Observation tracking (`withObservationTracking`) shows that a change to sign-in state notifies observers of `isSignedIn` and `statusText`. Drive it through a test seam that saves an hkey without the network (an invented `testuser` hkey, cleared afterwards)
- [x] 2.2 A UI test (`testSettings`, or a new one) with a launch argument that stubs a successful login (no network): after logging in, "Signed in as testuser" and "Log out" appear on Settings without switching tabs. Review the screenshot
