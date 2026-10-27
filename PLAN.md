# Flashcards iOS: Plan

A personal iOS app that is a new, modern frontend on top of Anki's open-source Rust engine
(`rslib` from https://github.com/ankitects/anki). It syncs with the official desktop Anki through
AnkiWeb, so desktop stays as-is and only the iPhone app is built here.

Personal use only: installed on my own iPhone from Xcode. No App Store, no TestFlight.

## Goals
- Open, review and sync the same collection I use in desktop Anki (no export/import step).
- **Feature parity with desktop Anki 26.9.3** (the version installed on this Mac). Everything listed in
  "Feature parity" below, except the items marked out of scope.
- Scheduling, card rendering, and deck/note compatibility identical to Anki, because the same engine does them.
- **It must look good and feel modern:** a native iOS 26 app that follows Apple's design guidelines (see "Design standards").
- Extras on top: text-to-speech, translation, AI explanations.

## Non-goals
- Desktop app (official Anki desktop is used there).
- App Store distribution or public release.
- Re-implementing any scheduling, storage or sync logic in Swift.
- Python add-ons (they can't run on iOS; my profile currently has none installed).
- Using the name "Anki" or Anki branding for the app.

## Constraints
- **License:** Anki is AGPL-3.0. Fine for personal use. If this is ever published, it must be open-sourced under AGPL.
- **Signing:** a free Apple ID ("Personal Team"). The installed app expires every 7 days and must be re-run from Xcode
  (or auto-refreshed via SideStore). Data on the device is kept across re-installs as long as the bundle ID stays the same.
  Free accounts can't use some capabilities (push notifications, iCloud, possibly App Groups), so avoid depending on them.
- **Minimum OS:** iOS 26. That gives Liquid Glass, Foundation Models and the Translation framework. Confirm my iPhone runs it.
- **AnkiWeb:** check AnkiWeb's terms before relying on it from a third-party client. Fallback: Anki's built-in
  self-hosted sync server (`anki --syncserver` / the `anki-sync-server` binary) on my own machine.

## Prerequisites (not installed yet on this Mac)
- Xcode (from the App Store), then `sudo xcode-select -s /Applications/Xcode.app`
- Rust via rustup, plus targets: `aarch64-apple-ios`, `aarch64-apple-ios-sim`
- `protoc` if the Anki build needs it (`brew install protobuf`)
- iPhone: Settings → Privacy & Security → Developer Mode on; after first install, trust the developer
  profile under Settings → General → VPN & Device Management

## Architecture

```
SwiftUI app
  ├─ Native screens: decks, review, add/edit, browse, stats, settings, sync
  ├─ CardWebView (WKWebView): renders card HTML/CSS/JS exactly like Anki
  ├─ AnkiPageView (WKWebView): hosts Anki's own SvelteKit pages for complex, rarely used screens
  ├─ WKURLSchemeHandler
  │     ├─ serves collection.media/ files to both web views
  │     └─ answers the pages' POST /_anki/<method> calls by forwarding them to rslib
  ├─ Extras: AVSpeechSynthesizer, Translation framework, Foundation Models / Claude API
  └─ Backend.swift: typed Swift wrappers around protobuf calls
          │  (protobuf bytes in, protobuf bytes out)
Rust bridge crate (rslib-bridge)  →  static library, packaged as an XCFramework
  └─ depends on anki's rslib, pinned to the release tag matching desktop (git tag `26.09.3`)
```

### Rust bridge
- A small crate in this repo that depends on `rslib` from the Anki repo (git dependency pinned to the release tag, or a
  submodule checked out with `--recursive` so the translation submodules are present).
- Exposes a C ABI with only a few functions:
  - `open_backend(init_bytes) -> handle` (protobuf `BackendInit`: languages, server flag)
  - `run_method(handle, service, method, input_bytes) -> (ok, output_bytes)`. This wraps rslib's
    `Backend::run_service_method`; errors come back as an encoded `BackendError`.
  - `free_bytes(...)`, `close_backend(handle)`
- Build script (`scripts/build-xcframework.sh`) compiles for device and simulator, then bundles both with `xcodebuild -create-xcframework`.
- Reference implementation to copy patterns from: AnkiDroid's backend, https://github.com/ankidroid/Anki-Android-Backend
  (the `rsdroid` crate does exactly this over JNI). AnkiDroid also hosts Anki's web pages the same way described below.
- Long-running calls (sync, import, FSRS optimise) must run off the main thread, and progress is polled via the backend's
  `latest_progress` method.

### Swift side
- Generate Swift types from Anki's `proto/anki/*.proto` with `swift-protobuf` (`protoc-gen-swift`).
- Service and method indices: derive them from the proto files in the same order rslib's generated code does,
  rather than hard-coding them. Verify against the pinned Anki version.
- `Backend.swift` wraps only the methods the native screens need. The engine has ~280 methods (the list is in
  `anki/_backend_generated.py` in the desktop bundle); wrap them as each phase needs them.

### Reusing Anki's web pages
Desktop Anki 26.9.3 ships these screens as SvelteKit web pages (`_aqt/data/web/sveltekit`):
`deck-options`, `graphs`, `card-info`, `change-notetype`, `import-csv`, `import-page`, `image-occlusion`, `editor`, `congrats`.
Each page calls the backend with `POST /_anki/<method_name>` and a protobuf body (desktop's `aqt/mediasrv.py` handles this).
- Build them from the pinned Anki source (`ts/`) and bundle them in the app.
- Implement the same `/_anki/*` endpoints in the WKURLSchemeHandler, forwarding to rslib. Use `aqt/mediasrv.py` as the
  reference for which methods each page needs and any special cases.
- Inject a CSS override so the pages use the app's fonts and colours, and present them as sheets.
- Use them for complex, rarely used screens (deck options with the FSRS optimiser and simulator, change note type,
  CSV import, image occlusion). They get full parity quickly; a native version can replace any of them later.
  Screens used every day are native (see the table below).

### Data on the device
- The collection lives in the app's Documents folder: `collection.anki2` plus `collection.media/`.
- Automatic backups via the backend's `create_backup`, kept in the app's folder and visible in the Files app.
- The AnkiWeb login key is stored in the Keychain.
- AI explanations/translations are cached locally (a small SQLite/JSON store keyed by note ID and field hash). Optionally
  they can be written into an "Explanation" note field so they sync to desktop (off by default).

## Feature parity with desktop Anki 26.9.3
From the installed desktop app's modules (`aqt/*`) and backend methods. **Native** = built in SwiftUI.
**Web** = Anki's own page hosted in the app. **Out** = out of scope.

| Desktop feature | iOS | Phase | Notes |
|---|---|---|---|
| Deck list with due counts, collapse, deck overview | Native | 1 | `deck_tree`, `counts_for_deck_today` |
| Review: show answer, 4 grades + interval labels, undo/redo | Native | 1 | `get_queued_cards`, `describe_next_states`, `answer_card`, `undo`/`redo` |
| Flag, mark, bury, suspend, edit current card while reviewing | Native | 1 | `set_flag`, `bury_or_suspend_cards` |
| Card audio, auto-play, replay | Native | 1 | `extract_av_tags`, AVAudioPlayer |
| TTS tags (`{{tts}}`) and voice list | Native | 1 | `all_tts_voices` → AVSpeechSynthesizer |
| Type-in answer and diff | Native | 1 | `compare_answer`, `extract_cloze_for_typing` |
| Cloze, MathJax, LaTeX images in cards | Native | 1 | MathJax bundled in CardWebView |
| Congrats screen, custom study, unbury | Native | 1 | `congrats_info`, `custom_study`, `unbury_deck` |
| Import `.apkg` / `.colpkg` | Native | 1 | share sheet / Files; `import_anki_package` |
| AnkiWeb sync (collection and media), full sync prompt | Native | 2 | `sync_login`, `sync_collection`, `sync_media`, `full_upload_or_download` |
| Add cards: note type, deck, fields, tags, sticky fields | Native | 3 | `defaults_for_adding`, `add_note` |
| Field editor: rich text, cloze shortcut, insert image/photo, record audio | Native | 3 | `add_media_file`; camera/photo picker; AVAudioRecorder |
| Image occlusion | Web | 3 | `image-occlusion` page |
| Browser: search, sortable columns, sidebar (decks/tags/note types/flags) | Native | 3 | `search_cards`, `browser_row_for_id`, `all_browser_columns` |
| Browser actions: change deck, tags, reposition, set due date, forget/reset, delete | Native | 3 | `set_deck`, `set_due_date`, `schedule_cards_as_new` |
| Find and replace, find duplicates | Native | 4 | `find_and_replace` |
| Card info / review history | Web | 3 | `card-info` page |
| Previewer | Native | 3 | reuse CardWebView |
| Deck options presets, FSRS params, optimise, desired retention, simulator, load balancer, easy days | Web | 3 | `deck-options` page |
| Filtered decks | Native | 4 | `add_or_update_filtered_deck`, `rebuild_filtered_deck` |
| Statistics / graphs | Web, then native | 3 → 5 | `graphs` page first; native Swift Charts version later |
| Tags: rename, reparent, clear unused | Native | 4 | `rename_tags`, `reparent_tags`, `clear_unused_tags` |
| Note types: fields, card templates + styling, change note type | Native (fields/templates), Web (change) | 4 | `update_notetype`, `change-notetype` page |
| Import CSV/text | Web | 4 | `import-csv` page |
| Export `.apkg` / `.colpkg` / CSV | Native | 4 | `export_anki_package` etc.; share sheet |
| Tools: check database, check media, empty cards, trash/restore media | Native | 4 | `check_database`, `check_media`, `get_empty_cards` |
| Preferences (scheduling, review, display) | Native | 2–4 | `get_preferences` / `set_preferences`; the app is dark-only in v1 |
| Backups | Native | 2 | `create_backup` |
| Multiple profiles | Out | – | one collection on the phone |
| Python add-ons, debug console, update checker | Out | – | not possible / not needed on iOS |
| AnkiHub | Out (maybe later) | – | backend supports `ankihub_login` |

## Extras (not in desktop Anki)
- **Swipe to grade:** swipe right = Good, left = Again, as a shortcut alongside the four grade buttons (see Review screen).
- **Bundled "Chinese vocab (2-way)" note type** with picture, pinyin, example sentence and audio fields, styled to the Ink look.
- **Stroke order** for hanzi on the review card.
- **Speech for any card:** AVSpeechSynthesizer for cards without audio, with the voice language set per deck or per field.
- **Translation:** Apple's Translation framework (on-device, free).
- **Explanations:** Apple Foundation Models (on-device; needs an Apple Intelligence-capable iPhone). Optional fallback:
  my own Claude API key stored in the Keychain. Generated on demand from a button on the answer side, then cached.
- **Home-screen widget** with due counts, if App Groups work on a free account.

## Design standards
The app must look like a polished, current iOS app rather than a port of desktop Anki. The rules:

### Chosen look: "Ink" (dark, orange accent)
- **Mockups:** https://claude.ai/artifact/Tzxn8ujHR1tdPp7mnk5fCF, the bottom row ("B · …"). The top row (look A, light
  with indigo) was the alternative and is not being built. The mockup link is private to my account, so this section is
  the source of truth.
- **Dark-only for v1.** The app ignores the system light/dark setting. A light variant can come later.
- Mockup content (HSK decks, 吃 / 猫 cards, all numbers) is sample data.

#### Colour tokens
Define these once (asset catalog plus a `Theme.swift`) and use only the tokens, never raw hex values in views.

| Token | Value | Used for |
|---|---|---|
| `bg` | `#0B0B0F` | screen background |
| `surface` | `#17171C` | deck tiles, stats panels, form fields |
| `card` | `#1A1A20` | the review card |
| `control` | `#1C1C22` | round icon buttons (close, sync, undo, more) |
| `raised` | `#22222A` / `#2A2A32` | chips, tags, explanation panel, speaker button, empty progress track |
| `hairline` | white at 8% | borders, dividers |
| `text` | `#F5F5F7` | primary text |
| `text2` | `#D4D4D8` | secondary text, inactive tab labels |
| `muted` | `#A1A1AA` | captions, labels, field titles |
| `zero` | `#8A8A93` | zero counts, placeholders |
| `accent` | `#FF8A3D` | primary buttons, selected states, pinyin, progress, review count, Good |
| `onAccent` | `#0B0B0F` | text and icons on accent fills |
| `new` | `#7DD3FC` | new-card counts and bars |
| `learning` | `#C4B5FD` | learning-card counts and bars |
| `again` | `#FB7185` | Again grade, left-swipe tint |
| `easy` | `#7DD3FC` | Easy grade |
| `synced` | `#86EFAC` | sync-status dot |
| heatmap | `#1F1F26`, `#4A2A17`, `#7A3F1C`, `#C2611F`, `#FF8A3D` | 5-step review heatmap, none → most |

#### Type
- **Display:** Space Grotesk, weight 600 (bundled; SIL Open Font License). Used for big numbers (due count, retention),
  screen titles, the English answer on cards, count rows and the grade stamp. Scale it with Dynamic Type via
  `Font.custom(_:size:relativeTo:)`.
- **Body/UI:** SF Pro (system). The mockups use Inter as a stand-in.
- **Chinese:** PingFang SC (system). The mockups use Noto Sans SC as a stand-in. Pinyin is always shown in `accent`.
- **Sizes (pt, at default Dynamic Type):** due count 96, retention 72, hanzi on the review card 60, hanzi in the add
  field 44, screen titles 34, answer 28, body 15–17, captions 12–13, field labels 12 uppercase with letter spacing.

#### Shape, materials, motion
- Corner radii: review card 30, panels and tiles 22–26, photo 20, chips and pills fully rounded, icon buttons 44 pt circles.
- The tab bar and the grade bar float above content as dark glass capsules (`.glassEffect` tinted dark, or
  `.ultraThinMaterial` over `bg`), with a hairline border and a deep shadow.
- Icons: SF Symbols only. The mockups' line icons map to `arrow.triangle.2.circlepath`, `plus`, `xmark`,
  `arrow.uturn.backward`, `ellipsis`, `speaker.wave.2`, `sparkle`, `camera`, `photo.on.rectangle`, `mic`, `magnifyingglass`.
- Springy, short animations. Haptics on grading and on crossing the swipe threshold (`.sensoryFeedback`).
  Reduce Motion swaps slides and tilts for fades.

### Foundation
- Follow Apple's Human Interface Guidelines and the iOS 26 design language (Liquid Glass), themed with the Ink tokens.
- Use standard SwiftUI building blocks (`NavigationStack`, `TabView`, toolbars, sheets, `searchable`, `List`) styled
  with the tokens, rather than custom re-implementations.
- **Navigation:** a floating tab bar with Decks, Browse, Stats, Settings (selected tab: accent icon and label on an
  accent-tinted pill). Review and Add card open full screen. No hamburger menus.
- **Type:** Dynamic Type everywhere, including the display font. Nothing hard-coded to a fixed size.
- **Colour:** only the Ink tokens. Colour is never the only signal: counts and grades always carry a label.
- **Touch:** targets at least 44×44 pt. Frequent actions sit in the bottom third of the screen, within thumb reach.

### Screens

#### Decks (home tab)
- Top row: today's date with a quiet sync status underneath (`synced` dot + "Synced 2 min ago"), and round Sync and
  Add-card buttons on the right.
- Hero: total due count in 96 pt display type with "cards due", and a line underneath with estimated time, cards done
  today and the streak.
- A stacked bar splitting due cards into new / learning / review, with a labelled legend under it.
- A full-width accent "Start review" pill (studies all decks).
- "Decks" heading, then a 2-column grid of deck tiles. Each tile shows: a large glyph (for HSK decks the level numeral
  一 二 三 四; otherwise the first character of the deck name), the deck name, the word count, new / learning / review counts
  in their colours (zeros in `zero`), and a thin progress bar for the deck. Tap opens that deck's overview; subdecks
  open a nested grid.
- Pull to refresh runs a sync.

#### Review (full screen)
- **Header:** close button; a progress bar with the session's remaining new / learning / review counts under it;
  Undo; a "⋯" menu (flag, mark, bury, suspend, card info, edit).
- **Card:** a `card`-coloured panel that fills the middle of the screen, with the next card peeking out behind it.
  Native chrome around a WKWebView for the card body. On the answer side, top to bottom:
  1. **Picture** (rounded, about 130 pt tall) from the note's image field, with a small deck tag on it. No image means no gap.
  2. **Hanzi** large, with **pinyin** in accent beside it, and a round speaker button (deck audio first, then TTS).
  3. A hairline divider.
  4. **English meaning** in the display font.
  5. **Example sentence** with the target word highlighted in accent, then pinyin and translation in `muted`.
  6. **Action chips:** Explain (accent fill), Stroke order, Edit.
  7. **Explanation panel** (`raised` background, accent "EXPLANATION" label): appears when Explain is tapped; the result
     is cached per note so it shows instantly next time.
- The question side shows only what the note type puts on the front (for the Chinese note type: the hanzi, or the
  English on reverse cards). Tap anywhere on the card to reveal the answer.
- **Grade bar:** four buttons, Again / Hard / Good / Easy, each with its next interval under it ("1m", "2d", "3d", "8d")
  from the scheduler. Colours: Again `again`, Hard `text2`, Good filled `accent` with `onAccent` text (the default
  action), Easy `easy`.
- **Swipe shortcut:** right = Good, left = Again. While dragging, the card tilts, gets an accent (right) or `again` (left)
  edge glow and a stamp ("GOOD · 3d" / "AGAIN · 1m"), with a haptic tick at the commit threshold. A small hint line
  above the grade bar explains this until the user has swiped a few times.
- **How the card body gets this layout:** the app ships a **"Chinese vocab (2-way)" note type** (fields: Hanzi, Pinyin,
  English, Picture, Example, Example pinyin, Example English, Audio), whose template and CSS produce the layout above
  inside the WKWebView. Other note types render with their own templates on top of the base stylesheet. Imported HSK
  decks can be switched to the bundled note type with Anki's change-note-type flow. The header, chips, explanation
  panel and grade bar are native and appear for every note type.

#### Add card (full screen)
- Header: close button and a "New card" title.
- Chips for deck and note type (each opens a picker).
- **Hanzi** field (44 pt, accent focus ring) beside a square **picture tile**. Tapping the tile offers search images,
  camera or photo library.
- **Pinyin** (accent text) and **English** fields side by side; **Example** field below.
- **"Auto-fill example, audio and picture"** outline button (accent): fills the empty fields with AI, TTS and image
  search. The user can edit everything before adding.
- Tags as chips, with a "+ tag" chip.
- A floating formatting toolbar above the keyboard: bold, italic, underline, cloze, photo library, camera, record audio.
- A full-width accent **"Add card"** button. The deck and note type stay selected for the next card.
- The fields follow the selected note type; the layout above is for the Chinese note type, and other note types get
  one field block per field.

#### Stats (tab)
- Title with an "All decks" picker; a range selector (Week / Month / Year) as chips, with the selected chip filled accent.
- **Hero panel:** true retention as a big percentage, with the target under it ("Above your 90% target"), plus the
  streak and today's time and card count on the right.
- **Heatmap:** reviews for the last 16 weeks, 7 rows by 16 columns, using the 5-step orange scale and a "Less → More" legend.
- **Forecast:** due cards for the next 7 days as bars, with today in accent and other days in `raised`, plus day labels.
- Until the native Swift Charts version (Phase 5), the Stats tab hosts Anki's `graphs` page with the Ink CSS override.

### Everywhere else
- Sync status is quiet: the status line on the Decks screen, never a blocking dialog, except for the full-sync choice.
- Every screen has designed empty, loading and error states in the same style.
- Hosted Anki web pages (deck options, card info, etc.) get a CSS override with the Ink tokens and fonts.
- Accessibility: VoiceOver labels on all controls (e.g. deck tiles read "HSK 2: 5 new, 2 learning, 41 review"),
  contrast of at least 4.5:1 for text, and everything works at the largest text sizes.

### Process
- **Mockups are agreed** (look B above). Build to this section; where something isn't specified, follow the mockups' style.
- Every screen has SwiftUI previews at the default and at a large Dynamic Type size.
- At the end of each phase, take simulator screenshots of each screen and review them against this section and the mockups
  before calling the phase done.

## Phases and definition of done

### Phase 0: toolchain and engine running
- Prerequisites installed. Bridge crate builds an XCFramework for device and simulator.
- **Done when:** the app runs in the simulator, opens a bundled sample collection, and prints the deck tree from rslib.

### Phase 1: reviewing works
- Every Phase 1 row in the parity table, plus the Ink theme tokens and fonts, the Decks and Review screens as specified
  in "Screens", the swipe shortcut, and the bundled Chinese note type.
- **Done when:** I can import one of my decks on the iPhone and review it, scheduling matches what desktop Anki shows,
  and the screens pass the design review.

### Phase 2: sync, backups, basic preferences
- AnkiWeb login and normal sync, including media. Handle the "full sync required" choice (upload vs download) with a clear prompt.
- **Done when:** a review done on the phone appears in desktop Anki after syncing both, and vice versa.

### Phase 3: create and manage
- Phase 3 rows: add/edit cards (Add card screen as specified), browser, card info, deck options, stats (web, Ink
  CSS override), image occlusion. Also speech, translation, AI explanations and auto-fill, and stroke order.
- The web-page bridge (`/_anki/*` scheme handler) is built in this phase.
- **Done when:** I can add a card with an image on the phone, change a deck's FSRS settings, and both sync to desktop.

### Phase 4: the rest of parity
- Phase 4 rows: filtered decks, tags, note types, CSV import, export, tools, find and replace/duplicates.
- **Done when:** every in-scope row in the parity table is ticked off.

### Phase 5: nice-to-have
- Native Swift Charts statistics (heatmap, retention, forecast), widget, app icon and final polish.

## Risks
- **Building rslib for iOS** (code generation, translation submodules, bundled SQLite). Tackle this first, in Phase 0.
- **Proto drift:** service/method indices change between Anki versions. Pin one version and regenerate on upgrade.
- **AnkiWeb compatibility:** the sync protocol is versioned. Pin rslib to the same version as desktop (git tag `26.09.3`) and
  upgrade both together.
- **Web page bridge:** some `/_anki/*` endpoints have special handling in `mediasrv.py`. Port those deliberately rather
  than forwarding blindly.
- **The 7-day expiry:** re-running from Xcode re-signs the app without losing data.
