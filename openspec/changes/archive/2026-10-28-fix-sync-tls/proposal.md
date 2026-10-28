## Why
The user tried to log in to AnkiWeb and got "A network error occurred", on a working network.

The cause: Anki's workspace declares `reqwest` with `default-features = false`, and `rslib` only adds a TLS backend through its own features (`rustls` or `native-tls`), which the embedding app has to turn on. Desktop Anki turns one on in its own build; `crates/rslib-bridge/Cargo.toml` doesn't. So the engine in the XCFramework has no TLS: every `https://` request fails before it leaves the device, and the engine reports it as a network error. Login, normal sync and media sync are all broken.

## What Changes
- `crates/rslib-bridge/Cargo.toml`: depend on `anki` with `features = ["native-tls"]`. On iOS, `native-tls` uses Security.framework and the system trust store. Don't use `rustls`: its `rustls-tls-native-roots` can't load the system roots on iOS.
- Link whatever the Xcode target needs for native-tls (Security.framework is likely already linked through the system; add it in `app/project.yml` if the link fails).
- Rebuild `build/RslibBridge.xcframework` with `scripts/build-xcframework.sh` (cargo `-j2`) for device and simulator.
- The login error shows the engine's detail when there is one, so a future failure says why (for example a TLS or DNS error), not just "network error".

## Impact
`crates/rslib-bridge/Cargo.toml`, `Cargo.lock`, maybe `app/project.yml`, `app/Cornhub/Sync/*`. No sync logic in Swift. Tests never sync a real AnkiWeb account.
