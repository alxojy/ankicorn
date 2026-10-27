# ankicorn: rules for every agent

A personal iOS app called **Cornhub** (SwiftUI, iOS 26) on top of Anki's Rust engine (`rslib`, pinned to git tag `26.09.3`), syncing with desktop Anki through AnkiWeb. `PLAN.md` is the product plan, the parity table, the phases and the design standard ("Ink" look). Read the part you are working on before you start.

## DEMO MODE (in force now; overrides the test rules below)

This build is a demo. **Do not write or run tests, and do not review screenshots.** `npm run gate` only checks the protected files, the ledger, the specs, `cargo fmt` and that the app compiles (`xcodebuild build`). The orchestrator runs the full sweep (`ANKICORN_FULL=1 npm run gate`) after all the changes have landed, and fixes what breaks. Everything else below still applies: ledger, OpenSpec, commit and push, no protected-file edits, and self-merge with `npm run gate`. Iterate with `xcodebuild build` only.

## How work is accepted: the gate, not review

There is **no human or orchestrator code review**. Work is accepted only by mechanical proof:

1. `npm run gate` passes locally on the exact commit (protected-file check, ledger check, spec check, tests-required check, and `npm run verify`: fmt, clippy, Rust tests, SwiftLint, Xcode unit and UI tests on the simulator).
2. The ledger `finish` entry quotes the `GATE PASSED @<sha>: …` line.

CI (the `gate` GitHub Actions run) is a **non-blocking backstop**. Agents never wait for it. The local gate is the merge proof. The orchestrator watches `main` CI in the background; when `main` goes red it triages and assigns the fix.

**Code is only "working" if tests prove it.** Every Swift change ships with unit or UI tests under `app/*Tests/` that exercise each behaviour it adds or changes. Every Rust change ships with a `#[test]` or a test in `crates/*/tests/`. UI work is also checked visually: the UI tests attach simulator screenshots, and the implementing agent reviews them against the "Design standards" in `PLAN.md` before ticking anything. Specs-only work is proven by `node tools/check-spec.mjs` (OpenSpec strict validation).

The pre-push hook to `main` runs the gate with `--final`: every `start` ledger entry in the range needs a `finish` entry that quotes `GATE PASSED @<sha>`. Iterate with narrow test runs (`cargo test -p <crate> -j2`, `xcodebuild test -only-testing:…`) and run the full gate once, on the final rebased commit.

## Machine limits (8 GB RAM, limited disk)

- **One worker at a time.** Never run two builds in parallel.
- Cargo always with `-j2` (`CARGO_BUILD_JOBS=2`). Never run a `cargo` build while Xcode is building or the simulator is running UI tests.
- One simulator at a time; `-parallel-testing-enabled NO`.
- Keep the Anki checkout shallow (`--depth 1` at the pinned tag). Delete `target/`, `DerivedData/` and unused simulator runtimes when told disk is tight; never commit build output.

## Non-negotiables

1. **Commit and push as you go.** Commit after every meaningful step and push right away. Never leave finished work uncommitted or unpushed. Use Conventional Commits (`feat(review): …`), which the commit-msg hook enforces.
2. **Never bypass the checks**: no `--no-verify`, no `XCTSkip`/`#[ignore]`/disabled tests, no lowered lint rules. Do not change protected files: `tools/` gate/check/ledger/verify scripts, `.githooks/`, `.github/workflows/`, `.swiftlint.yml`, `rustfmt.toml`, `clippy.toml`, `rust-toolchain.toml`, and the `scripts` in `package.json`. The gate rejects such commits unless they carry `Protected-Change-By: orchestrator`, and only the orchestrator may add that trailer. If a check seems wrong, stop and report it.
3. **Append-only ledger.** Use `node tools/ledger.mjs` to add a line to `ledger/LEDGER.jsonl` when you start, finish or correct a task. Never edit or delete lines; fix mistakes with a `correction` entry. Hooks and the gate enforce this.
4. **OpenSpec drives the work.** Current behaviour is in `openspec/specs/<capability>/spec.md`. Every piece of work is a change in `openspec/changes/<change-id>/` (`proposal.md`, `tasks.md`, spec deltas, `design.md` if needed).
5. **Checkboxes mean proven.** The implementing agent ticks a `- [ ]` in `tasks.md` only after the gate passes for that work, and in the same commit as its ledger `finish` entry. Archive a change (`npx openspec archive <id>`) only when every box is ticked and the gate passes; do it in the same push as the merge.
6. **The engine does the work.** Scheduling, storage, sync, search, import/export and card rendering come from `rslib` through the bridge. Never re-implement them in Swift. Wrap the backend method instead (`Backend.swift`), deriving service and method indices from the pinned `.proto` files.
7. **Design is tokens.** Colours, fonts, radii and spacing come from `Theme.swift` and the asset catalog, using the Ink tokens in `PLAN.md`. No raw hex values or fixed font sizes in views. Dynamic Type, VoiceOver labels, 44 pt targets and SF Symbols only.
8. **No private data in the repo.** No AnkiWeb credentials or keys, no real collection (`*.anki2`, `*.colpkg`, `*.apkg`, `collection.media/` are gitignored). Tests use a small bundled sample collection and invented content; use `testuser` for any name. Never sync a real AnkiWeb account from tests.
9. **License and name.** Anki is AGPL-3.0; keep license notices intact. The app is called Cornhub; do not use Anki branding for its display name or icon.

## Merging (self-service, gated)

```sh
git fetch origin && git rebase origin/main      # stay current
npm run gate                                      # must pass
git push -u origin HEAD                           # branch backup
git push origin HEAD:main                         # fast-forward only; the pre-push hook re-runs the gate
```

If the fast-forward is rejected, rebase and repeat. **Never wait for CI** (`gh run watch`, poll loops); move on as soon as `main` contains your commit. If the orchestrator reports a red `main` that your change caused, fixing it is your top priority: push a fix and add a `correction` ledger entry.

## Layout

```
PLAN.md                     product plan, parity table, phases, design standard
crates/rslib-bridge/        Rust C-ABI bridge over rslib (path dependency on the third_party/anki submodule, tag 26.09.3)
third_party/anki/           Anki submodule (shallow, tag 26.09.3); run scripts/setup-engine.sh to check it out
app/Cornhub.xcodeproj      Xcode project
app/Cornhub/               SwiftUI app: Backend/ (typed protobuf wrappers), Theme/, Screens/, Web/ (WKWebView + scheme handler)
app/CornhubTests/          unit tests
app/CornhubUITests/        simulator UI tests (attach screenshots)
web/                        build glue for Anki's SvelteKit pages (Phase 3)
scripts/                    setup-engine.sh (submodules), build-xcframework.sh (-> build/RslibBridge.xcframework)
docs/CONVENTIONS.md         code conventions
openspec/                   specs and changes
ledger/LEDGER.jsonl         append-only task log
tools/                      gate, checks, ledger, verify
```

Not all of this exists yet; Phase 0 creates the bridge crate and the Xcode project.

## Roles

- **Orchestrator (Opus)**: writes the specs and changes, splits work into tasks, dispatches agents one at a time, watches `main` CI in the background and triages red runs, and owns protected files. It does not review code.
- **Implementers (Sonnet subagents)**: one change or task each. They follow the `ankicorn-agent-workflow` skill, prove their work with the gate and tests, and merge their own work once it is green.

## Skills

- `ankicorn-agent-workflow`: worktree, ledger, testing, commit and push, self-merge (always load first)
- `ankicorn-ios-feature`: building Rust bridge, backend wrappers and SwiftUI screens, with test and screenshot proof
- `openspec-*`: propose, explore, apply, update, sync and archive changes

## Commands

- `scripts/bootstrap.sh`: engine, XCFramework (if missing), `gen-swift-protos.sh`, `gen-service-index.mjs`, XcodeGen. `app/project.yml` is the project source; regenerate `app/Cornhub.xcodeproj` after editing it
- `xcodebuild test -project app/Cornhub.xcodeproj -scheme Cornhub -destination 'platform=iOS Simulator,name=iPhone 17' -jobs 2 -parallel-testing-enabled NO [-only-testing:…]`: Xcode tests, serial
- `npm run gate`: the acceptance check (run before any push to `main`)
- `npm run verify`: fmt, clippy, Rust tests, SwiftLint, Xcode tests (only the parts that exist)
- `node tools/ledger.mjs …`: append to the ledger; `node tools/check-ledger.mjs [base] [--final]`
- `npx openspec list | validate --all --strict | archive <id>`
- Conventions: `docs/CONVENTIONS.md`
