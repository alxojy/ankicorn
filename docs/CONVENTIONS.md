# Conventions

Enforced by rustfmt, clippy, SwiftLint and the gate. Anything below that a tool cannot check is still required.

## Files and names
- Swift: one primary type per file, `PascalCase.swift`. Screens in `app/Cornhub/Screens/<Screen>/`, backend wrappers in `app/Cornhub/Backend/`, design tokens in `app/Cornhub/Theme/`.
- Tests: `app/CornhubTests/<Unit>Tests.swift`, `app/CornhubUITests/<Screen>UITests.swift`.
- Rust: `snake_case` modules, crate `rslib-bridge`; integration tests in `crates/rslib-bridge/tests/`.
- Backend wrappers are named after the rslib method in `lowerCamelCase` (`get_queued_cards` becomes `getQueuedCards`).

## Swift
- Swift 6 language mode, strict concurrency. `async`/`await`; long backend calls never run on the main actor.
- No force unwraps or `try!` outside tests. Errors from the backend surface as typed `BackendError` values shown in a designed error state.
- No scheduling, storage or sync logic in Swift. If you need a number the engine already computes, call the engine.
- Views take their data from view models or plain values, so previews work with sample data.

## Design
- Colours, fonts and radii come from `Theme.swift`, using the Ink tokens in `PLAN.md`. No raw hex values or fixed point sizes in views.
- Dark only in v1. Every screen has previews at the default and at a large Dynamic Type size.

## Rust
- The bridge crate stays small: C ABI, error encoding, buffer freeing. `unsafe` only at the FFI boundary, each block with a `// SAFETY:` comment.
- `cargo fmt`, `cargo clippy -D warnings`. Build with `-j2`.

## Tests
- No `XCTSkip`, `#[ignore]`, `.disabled(...)` or `XCTExpectFailure`. Fix the test.
- UI tests attach screenshots and assert user-visible results, not implementation details.
- Test data is the bundled sample collection or invented content (`testuser`). Never a real collection, never a real AnkiWeb login.

## Commits
- Conventional Commits (`feat(review): add grade bar`). Small commits, pushed right away.
- Never `--no-verify`. Never edit protected files (see `tools/gate.mjs`).
