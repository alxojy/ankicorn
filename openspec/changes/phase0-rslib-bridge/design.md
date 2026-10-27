## Context

A spike (scratchpad, not committed) showed `cargo check --target aarch64-apple-ios` passing for a path dependency on `rslib` in 1m20s at `-j2`. `cargo check` also runs build scripts, so the C dependencies (bundled SQLite, zstd) compiled for iOS. It did not link or produce a library, and release builds are untested. AnkiDroid's `rsdroid` and Anki's own `pylib/rsbridge` are the reference patterns; `rsbridge` calls `init_backend(bytes)` and `backend.run_service_method(service, method, bytes)`.

## Decisions

- **Vendor Anki as a submodule at `third_party/anki`, shallow, tag `26.09.3`.** Chosen over a cargo git dependency because the build also needs Anki's `Cargo.lock`, `proto/` (for Swift codegen later) and the `ftl` submodules. A git dependency would not give us those paths.
- **Own Cargo workspace at the repo root with `crates/rslib-bridge`**, depending on `anki = { path = "../../third_party/anki/rslib" }`. Anki's `Cargo.lock` is copied to the root and kept in sync by the build script check (a test fails if the two differ), so versions stay pinned to the tag.
- **Enable `tokio` feature `io-util` in the bridge.** `rslib` relies on another workspace member to enable it; compiled alone it fails with 7 errors (`AsyncReadExt`, `AsyncWriteExt`).
- **Set `PROTOC` explicitly** in the build script (`command -v protoc`, fallback `/opt/homebrew/bin/protoc`), since cargo build scripts did not see it on PATH in a background shell.
- **Check out `ftl/core-repo` and `ftl/qt-repo`** shallow. `rslib/i18n/gather.rs` panics if `ftl/qt-repo` is empty.
- **Toolchain:** use the installed stable Rust rather than Anki's pinned 1.97.1 (the spike compiled with 1.99.1). `rust-toolchain.toml` pins `stable` channel components so everyone matches; revisit if a build breaks. UNVERIFIED for release builds.
- **ABI shape:** `open_backend(ptr,len) -> *mut Backend`; `run_method(handle, service, method, in_ptr, in_len, out: *mut ByteBuf) -> bool` where `ByteBuf { ptr, len, cap }`; `free_bytes(ByteBuf)`; `close_backend(handle)`. Panics are caught with `catch_unwind` and returned as an encoded error. `unsafe` stays inside these four functions with `// SAFETY:` comments.
- **No DB command function.** `rsbridge` also exposes `run_db_command_bytes` for Python's DB proxy; Swift never touches the database directly, so it is omitted.
- **Header:** `cbindgen`-free; a small hand-written `rslib_bridge.h` kept next to the crate and checked by a test that compares the declared function names to the exported symbols.
- **XCFramework:** `cargo build --release --target aarch64-apple-ios` and `aarch64-apple-ios-sim` (`-j2`, serial), then `xcodebuild -create-xcframework -library … -headers …` for both. Output in `build/` (git-ignored). Release profile uses `opt-level = "s"`, `lto = "thin"`, `strip = "debuginfo"` to limit size and link memory. UNVERIFIED: link memory use and size on 8 GB.

## Risks / Trade-offs

- A release build may run out of memory: retry with `-j1`, and consider `codegen-units = 16` or dropping LTO.
- Anki's lock file drifts if someone bumps one without the other; the sync test guards it.
- Service and method indices are not decided here. Tests that make a real call need one trivial method's indices from rslib's generated code; finding them is the first task, and the general derivation belongs to the Swift Backend change.

## Open Questions

- Does the iOS simulator slice need `x86_64`? Assume no: Apple-silicon Mac only.
