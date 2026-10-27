# Proposal

## Why

Every Cornhub feature runs on Anki's Rust engine (`rslib`), so nothing else can start until `rslib` builds for iOS and the app can call it. PLAN.md names this the biggest risk ("Building rslib for iOS") and says to tackle it first. A spike has already shown that `cargo check` for `aarch64-apple-ios` passes with a small bridge crate; this change turns the spike into the real, repeatable build.

## What Changes

- Add Anki as a shallow git submodule pinned to tag `26.09.3`, with its two translation submodules (`ftl/core-repo`, `ftl/qt-repo`) checked out shallow.
- Add the `rslib-bridge` crate (`crates/rslib-bridge/`) exposing a four-function C ABI: `open_backend`, `run_method`, `free_bytes`, `close_backend`.
- Add `scripts/build-xcframework.sh`, which builds the crate for device and simulator and bundles both into an XCFramework (git-ignored build output).
- Add Rust tests for the ABI (lifecycle, error encoding, memory ownership).
- Add the Rust workspace files the gate already expects (`Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, `rustfmt.toml`, `clippy.toml`).

Out of scope (separate changes): the Xcode project, the Swift `Backend` wrapper, protobuf code generation for Swift, service/method index derivation, and the "print the deck tree in the simulator" step that completes Phase 0.

## Capabilities

### New Capabilities
- `engine-bridge`: the C ABI over `rslib`, how it is pinned and built, and how it is packaged for iOS.

### Modified Capabilities
<!-- none -->

## Impact

- PLAN.md: Phase 0 (first half: "Bridge crate builds an XCFramework for device and simulator"). No parity-table rows are touched.
- New: `crates/rslib-bridge/`, `third_party/anki` (submodule), `scripts/build-xcframework.sh`, Rust workspace files at the repo root.
- Build needs `protoc`, Xcode's iOS SDK and the `aarch64-apple-ios` / `aarch64-apple-ios-sim` Rust targets (all installed). The release build is memory heavy on the 8 GB dev machine and runs at `-j2`.
- Licence: the crate links AGPL-3.0 code; licence notices stay intact.
