---
name: ankicorn-ios-feature
description: How to build a feature in ankicorn end to end - rslib bridge method, typed Backend.swift wrapper, SwiftUI screen styled with the Ink tokens, and the unit, UI and screenshot proof the gate and PLAN.md require. Load after ankicorn-agent-workflow when implementing a change.
---

# Building an ankicorn feature

Load `ankicorn-agent-workflow` first. The product plan, parity table and design standard are in `PLAN.md`; the change's `proposal.md`, `tasks.md` and spec deltas say what to build.

## Layers (bottom up)

1. **Rust bridge** (`crates/rslib-bridge/`): a thin C ABI over `rslib` (`open_backend`, `run_method`, `free_bytes`, `close_backend`). Add Rust code only for the bridge itself, never for scheduling, storage or sync. Pinned to the Anki git tag `26.09.3`; never bump it inside a feature change.
2. **Generated protobuf types**: Swift types come from Anki's `proto/anki/*.proto` through `swift-protobuf`. Service and method indices are derived from those files in rslib's order, never hard-coded; a unit test must check the ones you use against the pinned version.
3. **`Backend.swift` wrappers**: typed async functions for only the methods the feature needs, named after the backend method (`deckTree`, `getQueuedCards`, `answerCard`). Long calls (sync, import, optimise) run off the main thread and report progress via `latest_progress`.
4. **SwiftUI**: native screens use `NavigationStack`, `TabView`, `List`, sheets and `searchable` styled with `Theme.swift`. Card bodies render in `CardWebView` (WKWebView). Rarely used screens may host Anki's own Svelte pages through the `/_anki/*` scheme handler, as the PLAN.md parity table says per row.

## Design rules (checked by you, against screenshots)

- Only Ink tokens from `Theme.swift`; no raw hex, no fixed font sizes (`Font.custom(_:size:relativeTo:)` for Space Grotesk). Dark only in v1.
- 44 pt minimum targets, SF Symbols only, VoiceOver labels on every control (deck tiles read "HSK 2: 5 new, 2 learning, 41 review"), colour never the only signal.
- Every screen has designed empty, loading and error states, SwiftUI previews at default and at a large Dynamic Type size, and works at the largest text size.
- Springy short animations, haptics via `.sensoryFeedback`, Reduce Motion falls back to fades.

## Proof checklist (all required)

- Rust: `#[test]` or `crates/*/tests/` for each bridge behaviour; run with `cargo test -p rslib-bridge -j2`.
- Swift unit tests (`app/CornhubTests/`): Backend wrapper round trips against the bundled sample collection (never a real collection), view-model logic.
- Swift UI tests (`app/CornhubUITests/`): drive the screen on the simulator, assert the visible result, and attach a screenshot per state (`XCTAttachment`, lifetime `.keepAlways`) including empty, error and large Dynamic Type.
- Compare scheduling-related results with what rslib returns (interval labels from `describe_next_states`, due counts from `deck_tree`); never compute them in Swift.
- Review the attached screenshots against PLAN.md "Design standards" and list what you checked in the report.
- `npm run gate` passes; `finish` ledger entry quotes it.

## Memory and disk

One build at a time. `cargo` with `-j2`; do not run it while Xcode builds. Do not create extra simulators. If the Rust build is killed (out of memory), retry with `-j1` and report it.
