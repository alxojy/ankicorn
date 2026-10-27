## Context

The bridge change delivered `build/RslibBridge.xcframework` (slices `ios-arm64` and `ios-arm64-simulator`, module `RslibBridge`, header `rslib_bridge.h`) and tested the ABI in Rust. rslib's generated `backend.rs` has two dispatch families: even service numbers for the server-side traits and odd numbers for `Backend` (for example `35` is i18n, `7` is decks, `13` is scheduler). The bridge calls `Backend::run_service_method`, so only the odd family applies. Methods are numbered by their order in the service.

## Decisions

- **XcodeGen over a hand-written `.pbxproj`.** `app/project.yml` is the source; the generated `app/Cornhub.xcodeproj` is committed because `tools/verify.mjs` looks for it. A bootstrap check regenerates it and fails on a diff. XcodeGen is a Homebrew install (7.5 MB).
- **Targets:** `Cornhub` (app), `CornhubTests` (unit, hosted by the app), `CornhubUITests`. One shared scheme `Cornhub` runs both test targets. Deployment target iOS 26.0, `SWIFT_VERSION` 6, strict concurrency complete.
- **swift-protobuf via SPM**, pinned to the version matching the installed `protoc-gen-swift` (1.39.x). Generated files are committed so a fresh clone builds without the plugin.
- **Index table from rslib's generated code.** `scripts/gen-service-index.mjs` parses `backend.rs` from the Rust build output (`target/aarch64-apple-ios*/release/build/anki-*/out/backend.rs`): service names and numbers from the `Backend` `run_service_method` match, method names and numbers from each `run_backend_<service>_service_method` match. It writes `ServiceIndex.swift` and supports `--check`. This is authoritative for the pinned tag and needs no assumption about proto ordering. UNVERIFIED: the exact text of the generated match arms for method names; the script's first task is to confirm the parse and fail loudly if it cannot.
- **`Backend` is a Swift `actor`** (or holds a serial executor) owning the handle, so calls are serialised and run off the main thread; `deinit` closes the handle. A call encodes with swift-protobuf, copies the input pointer, calls `run_method`, copies the output into `Data`, and frees the `ByteBuf` in a `defer`.
- **`BackendError`** wraps the decoded protobuf `BackendError` (message, kind, help page, context).
- **Collection path:** `Documents/collection.anki2` with `collection.media/` and `collection.media.db2` beside it. Tests use a unique temporary directory per test.
- **Sample data is created through the engine** (`add_deck`), not a committed binary `.anki2`, so no collection file is ever in the repo. `--seed-sample` is read from `CommandLine.arguments`.
- **UI:** a plain SwiftUI `List` of the tree (indentation by depth), no Ink styling yet; the Ink theme and real Decks screen belong to Phase 1. Rows use `.accessibilityLabel`. The UI test attaches screenshots at the default and the largest accessibility text size.
- **Bootstrap script:** `scripts/bootstrap.sh` runs `setup-engine.sh`, builds the XCFramework only if missing, runs both generators and XcodeGen. It prints each step and never builds in parallel.

## Risks / Trade-offs

- Linking a 428 MB XCFramework into Xcode builds may be slow or memory heavy: `xcodebuild -jobs 2`, one simulator, no parallel testing. If Xcode is killed, report it instead of retrying in parallel.
- Parsing generated Rust is brittle; the `--check` drift test and a loud failure keep it honest, and a later change can switch to a descriptor-based generator.
- iOS 27.x simulator runtime is used to run an iOS 26 deployment target. UNVERIFIED on a physical iOS 26 device until the app is installed on the iPhone.
- Bundle id `com.alxojy.cornhub` must stay constant so on-device data survives free-account re-signing.

## Open Questions

- None blocking. Code signing for the physical device (free Personal Team) is configured later, when installing on the phone.
