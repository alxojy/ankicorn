## 1. TLS in the engine
- [x] 1.1 The bridge enables `anki/native-tls`; `cargo tree -p rslib-bridge -e features` shows reqwest with a TLS backend
- [x] 1.2 The XCFramework is rebuilt (device and simulator slices) and the app links and builds
- [x] 1.3 The login sheet shows the engine's error detail when the engine gives one

## 2. Proof
- [x] 2.1 A Rust test in `crates/rslib-bridge` proves HTTPS works without touching AnkiWeb: for example, a test that builds the engine's HTTP client and fetches an `https://` URL from a local TLS test server, or a compile-time/feature assertion that reqwest has `native-tls`. It must fail with the old Cargo.toml.
- [x] 2.2 On the simulator, logging in with invented credentials (`testuser@example.com`, a wrong password) returns AnkiWeb's authentication error, not a network error. Record the message seen. Do this manually once; don't put it in an automated test, and never use a real account.
