# Cornhub

<img width="528" height="276" alt="Screenshot 2026-10-27 at 9 25 34 PM" src="https://github.com/user-attachments/assets/16930bdf-6a1e-4943-a81e-92020cbbf6d4" />

A personal iOS flashcards app: a modern SwiftUI frontend on top of [Anki](https://github.com/ankitects/anki)'s open-source Rust engine (`rslib`). It opens the same collection as desktop Anki and syncs with it through AnkiWeb, so desktop stays as it is and only the iPhone app is built here.

The repo is called `ankicorn`; the app is called **Cornhub**.

## What it is

- **Same engine as Anki.** Scheduling, storage, sync, search and card rendering all come from `rslib`, pinned to git tag `26.09.3` to match desktop. Nothing is re-implemented in Swift, so scheduling and deck/note compatibility match desktop.
- **Native iOS 26 app.** SwiftUI with Liquid Glass, a dark "Ink" look with an orange accent, Dynamic Type, VoiceOver and haptics.
- **Feature parity with desktop Anki** for daily use: decks, review, add/edit, browser, stats, sync, import/export. Rarely used screens (deck options, image occlusion, CSV import) reuse Anki's own web pages inside the app.
- **Extras:** swipe to grade, text-to-speech, on-device translation and AI explanations, stroke order for hanzi, and a bundled Chinese vocab note type.

Personal use only: installed on my own iPhone from Xcode. No App Store or TestFlight.

## How it fits together

```
SwiftUI app
  ├─ native screens (decks, review, add, browse, stats, settings, sync)
  ├─ WKWebView for card rendering and hosted Anki pages
  └─ Backend.swift: typed wrappers over protobuf calls
          │
Rust bridge crate (rslib-bridge)  →  XCFramework (device + simulator)
  └─ rslib @ Anki tag 26.09.3
```

Details, the desktop parity table, the design standard and the phases are in [`PLAN.md`](PLAN.md).

## Status

Phase 0: the bridge builds, and the Xcode project, typed Swift `Backend` and a diagnostic screen that lists the deck tree returned by rslib are in place. Next is Phase 1 (Ink theme, real Decks and Review screens).

## Build and test

```sh
scripts/bootstrap.sh        # engine, XCFramework if missing, Swift protobufs, service index, Xcode project
xcodebuild test -project app/Cornhub.xcodeproj -scheme Cornhub \
  -destination 'platform=iOS Simulator,name=iPhone 17' -jobs 2 -parallel-testing-enabled NO
```

`app/project.yml` (XcodeGen) is the source of the committed `app/Cornhub.xcodeproj`; edit it and re-run `xcodegen generate --spec app/project.yml --project app`. `node scripts/gen-service-index.mjs --check` fails if the committed service table drifts from rslib's generated dispatch (pass the path to `backend.rs`, or set `BACKEND_RS`).

## Working in this repo

Work is done by AI agents under a mechanical gate instead of code review. Read [`CLAUDE.md`](CLAUDE.md) first; it covers the gate, the append-only ledger (`ledger/LEDGER.jsonl`), OpenSpec changes (`openspec/`) and the merge flow. Conventions are in [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md).

```sh
npm ci            # installs tooling and the git hooks
npm run gate      # the acceptance check; must pass before pushing to main
```

## Building the engine

```sh
git clone --recurse-submodules --depth 1 <repo>   # or, in an existing clone:
scripts/setup-engine.sh                           # Anki at tag 26.09.3 + its ftl submodules, shallow
scripts/build-xcframework.sh                      # build/RslibBridge.xcframework (git-ignored)
cargo test -p rslib-bridge -j2                    # bridge tests; always -j2 on an 8 GB machine
```

`CARGO_JOBS=1 scripts/build-xcframework.sh` retries with one job if the linker runs out of memory.

## Requirements

- macOS with Xcode 27 and the iOS simulator runtime
- Rust (rustup) with the `aarch64-apple-ios` and `aarch64-apple-ios-sim` targets, and `protoc`
- Node 20 for the repo tooling
- An iPhone on iOS 26 with Developer Mode on. A free Apple ID works, but the installed app expires every 7 days and must be re-run from Xcode.

## License

Anki is AGPL-3.0-or-later, and this project builds on it, so it is AGPL-3.0-or-later too if it is ever distributed. Anki is a trademark of its owners; Cornhub is an independent project and is not affiliated with Anki or AnkiWeb.
