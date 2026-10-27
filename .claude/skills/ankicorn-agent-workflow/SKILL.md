---
name: ankicorn-agent-workflow
description: Mandatory workflow for any agent doing work in ankicorn - own git worktree and branch, ledger start/finish entries, proving your own work with the gate and tests, commit-and-push cadence, gated self-merge to main, and the report format. Load before starting any ankicorn task.
---

# ankicorn agent workflow

Read `CLAUDE.md` first. There is no code review: **your proof is the local gate**. CI reruns it as a non-blocking backstop; never wait for CI. Work that is not proven is not done. The machine has 8 GB of RAM: one build at a time, cargo with `-j2`.

## 1. Own worktree and branch

Never work in the main checkout. If Orca gave you a worktree, skip this step and do not remove the worktree at the end.

```sh
git fetch -q origin
git worktree add ../ankicorn-wt/<task-id> -b <type>/<task-id> origin/main
cd ../ankicorn-wt/<task-id> && npm ci        # npm ci also installs the git hooks
git config core.hooksPath                    # must print .githooks
```

`<type>` is `spec`, `feat`, `fix`, `test` or `chore`. Run every later command inside the worktree.

## 2. Log the start (and push it)

```sh
node tools/ledger.mjs --agent <agent-name> --model <model-id> --change <change-id> \
  --task "<task text from tasks.md>" --event start
git add ledger/LEDGER.jsonl && git commit -m "chore(ledger): start <task-id>" && git push -u origin HEAD
```

## 3. Work in small, pushed steps

- Follow the spec, and `PLAN.md` when the spec is silent.
- After each meaningful step: run the relevant checks, commit (Conventional Commits), and push.
- Never use `--no-verify`, skipped tests or lowered lint rules. Never edit protected files (listed in CLAUDE.md). If a check looks wrong, stop and report it.

### Pushes must be verified

Never filter or silence `git push` output. After every push, confirm that the remote really has your commit:

```sh
git push origin HEAD && test "$(git rev-parse HEAD)" = "$(git rev-parse '@{push}')" && echo PUSH-OK
# for main: git fetch -q origin && test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" && echo MAIN-OK
```

A rejected push means nothing landed, whatever the gate said. Check `git status` before committing; `git add -A` must not pick up stray files (build output, `target/`, DerivedData, collections).

## 4. Prove it

**DEMO MODE (in force now):** skip the tests and screenshots described below. Make sure `xcodebuild build` succeeds, then run `npm run gate`, which runs a compile check only. The orchestrator does the test sweep at the end.

- **Specs**: `node tools/check-spec.mjs` (OpenSpec strict validation).
- **Rust**: `cargo test -p <crate> -j2` while iterating; tests for every behaviour you add or change.
- **Swift**: unit tests in `app/CornhubTests/`, UI tests in `app/CornhubUITests/` for every screen or flow you add or change. Run narrow: `xcodebuild test -only-testing:CornhubUITests/<Class>`.
- **Visual**: UI tests attach screenshots. Review them against the PLAN.md "Design standards" for that screen (tokens, type, radii, empty/loading/error states, large Dynamic Type) and note what you checked in your report.
- Finally run `npm run gate` and keep the `GATE PASSED @<sha>: …` line.

### Shared files: rebase early, append only

The Xcode project file, `Backend.swift`, the bridge's method table and `Theme.swift` are shared. Rebase on `origin/main` before you start and again before the final gate. Add your lines without reordering or reformatting what is there. Run `git status` after creating files to confirm they are tracked and, for the Xcode project, that new files are in the target.

## 5. Finish: tick, log, merge

```sh
# tick your boxes in openspec/changes/<change-id>/tasks.md, then:
node tools/ledger.mjs --agent <name> --model <model> --change <change-id> --task "<task>" \
  --event finish --files "<paths>" --commit HEAD --verification "<GATE PASSED line>"
npx openspec archive <change-id> --yes                         # when every box is ticked
git add -A && git commit -m "chore(ledger): finish <task-id>" && git push

git fetch origin && git rebase origin/main && npm run gate   # again if main moved
git push origin HEAD:main                                     # fast-forward; pre-push re-runs the gate
```

**The finish entry is enforced.** The pre-push hook runs `node tools/gate.mjs --final`, which rejects the push to `main` when a `start` entry in your range has no matching `finish` (same change and task text), or when a `finish` entry does not quote a `GATE PASSED @<sha>` line. So: (1) run the gate, (2) append the `finish` entry quoting its line, (3) tick the boxes in the same commit, (4) push. Re-check with `node tools/check-ledger.mjs origin/main --final` before pushing.

Do not run `gh run watch` or poll CI. Once `main` contains your commit (MAIN-OK), report and clean up.

- Fast-forward rejected: rebase, rerun the gate, and push again. Rebase conflicts in `tasks.md` or the ledger: keep both sides (the ledger uses union merge).
- The orchestrator watches `main` CI. If it sends you a red run your change caused, fix it immediately, add a `--event correction` ledger entry, and push.

## 6. Report back to the orchestrator

1. Branch and the commit merged to `main`.
2. What you did: files and capabilities.
3. The `GATE PASSED` line, and for code, the test files with what each proves, plus the screenshots reviewed for UI work.
4. Anything UNVERIFIED, plan gaps, or checks that seemed wrong.

Then clean up, once `main` is verified to contain your work (`git merge-base --is-ancestor HEAD origin/main`):

```sh
git push origin --delete <type>/<task-id>
git worktree remove ../ankicorn-wt/<task-id> && git branch -D <type>/<task-id>
```
