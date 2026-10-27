# Architecture

How Cornhub is put together, from the SwiftUI screens down to Anki's Rust engine. The diagrams are Mermaid, which GitHub renders inline. For what to build, see `PLAN.md`; for code rules, see `CONVENTIONS.md`.

## The big idea

Cornhub doesn't re-implement Anki. It embeds **Anki's own engine** (`rslib`, the Rust core that desktop Anki also uses) and puts a native iPhone interface on top. That's why the scheduling, the collection file format and AnkiWeb sync match desktop exactly: it's the same code, pinned to the same version (`26.09.3`).

```mermaid
flowchart TB
    subgraph iOS["Cornhub app (Swift)"]
        UI["SwiftUI screens<br/>Decks · Review · Add · Browse · Stats · Settings"]
        Models["View models<br/>(DeckHomeModel, ReviewModel, SyncModel, …)"]
        Backend["Backend actor<br/>typed wrappers: deckTree(), answerCard(), syncCollection() …"]
        Web["WKWebViews<br/>card bodies · Anki's own web pages"]
    end
    subgraph Rust["RslibBridge.xcframework (Rust, compiled for iOS)"]
        Bridge["rslib-bridge<br/>4 C functions"]
        Engine["rslib @ 26.09.3<br/>scheduler · SQLite storage · sync · search · rendering"]
    end
    Files[("On the phone<br/>Documents/collection.anki2<br/>Documents/collection.media/")]
    AnkiWeb(("AnkiWeb"))

    UI --> Models --> Backend
    UI --> Web
    Web -- "/_anki/* requests" --> Backend
    Backend -- "protobuf bytes" --> Bridge --> Engine
    Engine --> Files
    Engine <--> AnkiWeb
```

## Layer by layer

| Layer | Where | What it does |
|---|---|---|
| Engine | `third_party/anki/rslib` (git submodule, tag `26.09.3`) | Everything Anki actually *does*. Untouched upstream code. |
| Bridge | `crates/rslib-bridge/src/lib.rs`, `rslib_bridge.h` | A tiny C API so Swift can call Rust. ~100 lines of real code. |
| XCFramework | `build/RslibBridge.xcframework` (built, git-ignored) | The bridge plus engine compiled as a static library for iPhone and for the simulator. |
| Protobuf types | `app/Cornhub/Backend/Generated/*.pb.swift` | Swift structs generated from Anki's `.proto` files: the "language" Swift and Rust speak. |
| Service index | `app/Cornhub/Backend/ServiceIndex.swift` | Generated numbers that say *which* engine method to call. |
| Backend | `app/Cornhub/Backend/Backend*.swift` | A Swift `actor` with one typed function per engine method we use. |
| Screens | `app/Cornhub/Screens/*`, `Sync/`, `Web/` | SwiftUI views and their view models. |
| Theme | `app/Cornhub/Theme/` + asset catalog | The "Ink" colour tokens, Space Grotesk font, radii. |

### 1. The bridge: four C functions

Anki's engine already has a single entry point used by desktop Anki's Python: *"run method M of service S with these protobuf bytes, give me protobuf bytes back"*. The bridge just exposes that to C:

```c
void *open_backend(const uint8_t *init, size_t len);   // create an engine instance
bool  run_method(void *h, uint32_t service, uint32_t method,
                 const uint8_t *in, size_t len, ByteBuf *out);  // call anything
void  free_bytes(ByteBuf buf);                          // give Rust its memory back
void  close_backend(void *h);
```

`run_method` returns `true` with the response bytes, or `false` with an encoded `BackendError` (for example "deck not found"). The Swift side turns that into a typed `BackendError`.

### 2. What one call looks like

Example: the Decks screen asks for the deck tree.

```mermaid
sequenceDiagram
    participant V as DeckHomeScreen
    participant M as DeckHomeModel
    participant B as Backend (actor)
    participant R as rslib-bridge (C ABI)
    participant E as rslib engine
    V->>M: .task { await load() }
    M->>B: await deckTree(now:)
    Note over B: build Anki_Decks_DeckTreeRequest<br/>serialize to bytes
    B->>R: run_method(handle, Decks.service=7, Decks.deckTree, bytes)
    R->>E: backend.run_service_method(...)
    E-->>R: DeckTreeNode as protobuf bytes
    R-->>B: true + ByteBuf
    Note over B: copy bytes, free_bytes(),<br/>decode Anki_Decks_DeckTreeNode
    B-->>M: DeckTreeNode
    M-->>V: @Observable state changes, view redraws
```

Why an **actor**: calls run one at a time and never on the main thread, so the UI stays smooth. Long jobs that need progress reporting (sync, deck-options optimisation) use `callConcurrently`/`callRaw`, so `latestProgress` can be polled while they run.

### 3. Where the method numbers come from

The engine identifies methods by number, not name. Those numbers change between Anki versions, so they're never typed by hand:

```mermaid
flowchart LR
    P["third_party/anki/proto/anki/*.proto"] -- "scripts/gen-swift-protos.sh<br/>(protoc + protoc-gen-swift)" --> S["Generated/*.pb.swift<br/>request/response structs"]
    RS["rslib's generated backend.rs<br/>(method order per service)"] -- "scripts/gen-service-index.mjs" --> I["ServiceIndex.swift<br/>Decks.service = 7, Decks.deckTree = …"]
    S --> W["Backend+Decks.swift etc."]
    I --> W
```

Upgrading Anki = bump the submodule tag, rebuild the XCFramework, regenerate both. Desktop and phone must be on the same version for AnkiWeb sync.

## Rendering cards and Anki's web pages

Two kinds of web view, each with its own custom URL scheme so pages can load files without a web server:

```mermaid
flowchart TB
    subgraph Review["Review screen"]
        CW["CardWebView<br/>(card HTML from the engine)"]
    end
    subgraph Hosted["Deck options · Card info · Stats graphs"]
        AW["AnkiWebView<br/>(Anki's SvelteKit pages)"]
    end
    CW -- "cornhub://media/&lt;file&gt;" --> MS["MediaSchemeHandler"] --> MF[("collection.media/")]
    CW -- "cornhub://app/mathjax.js" --> AB[("app bundle")]
    AW -- "cornhub-web://app/deck-options/…" --> WS["AnkiWebSchemeHandler"] --> PB[("Resources/AnkiWeb/<br/>built by scripts/build-web.sh")]
    AW -- "POST /_anki/&lt;method&gt;<br/>(protobuf body)" --> WS --> API["AnkiWebAPI"] --> BK["Backend.callRaw"]
```

- **Card bodies**: the engine renders a card's question/answer HTML (templates, cloze, `{{tts}}`, `[sound:]` tags extracted separately). Cornhub wraps it in a page with the Ink base stylesheet and MathJax, and native SwiftUI chrome (header, grade bar, swipe gestures) sits around it. Audio plays natively (`CardAudio`: AVAudioPlayer for files, AVSpeechSynthesizer for TTS).
- **Hosted Anki pages**: rarely used, complex screens (deck options/FSRS, card info, graphs) are Anki's *own* Svelte pages, built from the pinned source. Desktop Anki serves them from a local Python web server (`mediasrv.py`); Cornhub replaces that server with `AnkiWebSchemeHandler`, which serves the files and forwards each `/_anki/<method>` call straight into the engine. An Ink CSS override makes them match the app.

## The review loop

```mermaid
sequenceDiagram
    participant U as You
    participant RS as ReviewScreen
    participant RM as ReviewModel
    participant B as Backend
    RM->>B: getQueuedCards()
    B-->>RM: next card + its scheduling states + counts
    RM->>B: renderExistingCard(), extract audio tags
    RM->>B: describeNextStates(states)
    B-->>RM: "1m · 6m · 1d · 4d" labels for the grade bar
    RM-->>RS: question HTML
    U->>RS: tap card
    RS->>RM: reveal() → answer HTML + grade bar
    U->>RS: tap Good / swipe right
    RS->>RM: answer(.good)
    RM->>B: answerCard(states, rating)
    Note over B: engine updates the card and<br/>writes the review log (SQLite)
    RM->>B: getQueuedCards() … repeat
    Note over RM: empty queue → congratsInfo() → Congrats screen
```

The intervals and due counts are always the engine's numbers, never computed in Swift. Undo/redo, bury, suspend, flag and custom study are each one engine call.

## Sync with AnkiWeb

```mermaid
flowchart TD
    A["Sync button / pull to refresh"] --> L{"Logged in?<br/>(hkey in Keychain)"}
    L -- no --> LS["LoginSheet → syncLogin()<br/>stores hkey, never the password"] --> S
    L -- yes --> S["syncCollection()"]
    S --> R{"response.required"}
    R -- "noChanges / normalSync" --> M["syncMedia() if enabled"] --> D["status line: 'Synced just now'"]
    R -- "fullSync / fullUpload / fullDownload" --> F["Prompt: upload or download?"]
    F --> BK["createBackup() first"] --> FU["fullUploadOrDownload()"] --> RO["reopen collection"] --> M
```

A normal sync merges changes both ways. A *full* sync (after schema changes, or the first time) replaces one side wholesale, so the app always asks and takes a backup first. Progress text comes from `latestProgress`, polled while the sync runs.

## Data on the phone

| What | Where |
|---|---|
| Collection (SQLite) | `Documents/collection.anki2` |
| Media | `Documents/collection.media/` |
| Backups | `Documents/` backups folder (`createBackup`) |
| AnkiWeb login key | Keychain (`AccountStore`) |
| Small preferences | `UserDefaults` (sync media on/off, etc.); scheduling prefs live in the collection |

Same file format as desktop, so `.colpkg`/`.apkg` import and AnkiWeb sync move data between them.

## Building it

```mermaid
flowchart LR
    A["scripts/setup-engine.sh<br/>shallow Anki submodule + ftl translations"] --> B["scripts/build-xcframework.sh<br/>cargo build for ios-arm64 + ios-arm64-simulator<br/>(-j2, ~20 min first time)"]
    B --> C["scripts/gen-swift-protos.sh<br/>+ gen-service-index.mjs"]
    C --> W["scripts/build-web.sh<br/>Anki's Svelte pages → Resources/AnkiWeb (~80 s)"]
    W --> X["xcodegen: app/project.yml → Cornhub.xcodeproj"]
    X --> Y["Xcode ⌘R"]
```

`scripts/bootstrap.sh` runs all of it in order and skips steps whose output already exists. The XCFramework and web pages are git-ignored build output; the generated Swift files and the Xcode project are committed.

## How the code gets written (the agent workflow)

The app is built by AI agents, coordinated rather than reviewed:

```mermaid
flowchart LR
    O["Orchestrator (Opus)<br/>splits PLAN.md into changes"] -- "one task at a time<br/>(8 GB RAM)" --> W["Worker (Sonnet)<br/>own git worktree via Orca"]
    W --> SP["writes OpenSpec change<br/>openspec/changes/&lt;id&gt;/"]
    SP --> IM["implements, commits, pushes"]
    IM --> G["npm run gate"]
    G --> LG["ledger 'finish' entry<br/>quotes GATE PASSED @sha"]
    LG --> M["push HEAD:main<br/>(pre-push hook re-runs gate)"]
    M -- "worker_done" --> O
```

- **OpenSpec** (`openspec/specs/`, `openspec/changes/`): each feature is a written change (proposal, tasks, spec delta) before code; archived changes become the living spec.
- **Ledger** (`ledger/LEDGER.jsonl`): append-only log of who started and finished what, with proof.
- **Gate** (`tools/gate.mjs`): protected-file check, ledger check, spec validation, then `tools/verify.mjs`. **Demo mode** (current) only checks formatting and that the app compiles; `ANKICORN_FULL=1` runs clippy, Rust tests and the Xcode unit/UI tests, which happens in the final sweep.

## Glossary

- **rslib**: Anki's Rust core library.
- **Collection**: your whole Anki database (decks, notes, cards, review history), one SQLite file.
- **Note / card**: a note holds fields (Hanzi, English…); its note type's templates generate one or more cards from it.
- **FSRS**: the modern scheduling algorithm in Anki; parameters live in deck options.
- **hkey**: the AnkiWeb session key returned by login; stored instead of your password.
- **XCFramework**: Apple's bundle format for a library built for several platforms (device + simulator).
- **Actor**: a Swift type whose methods run one at a time, off the main thread.
