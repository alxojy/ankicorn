## 1. Vendor the engine
- [ ] 1.1 Add `third_party/anki` as a shallow submodule at tag `26.09.3`; add `scripts/setup-engine.sh` that initialises it and `ftl/core-repo` + `ftl/qt-repo` shallowly (idempotent)
- [ ] 1.2 Add root `Cargo.toml` workspace, `rust-toolchain.toml`, `rustfmt.toml`, `clippy.toml`; copy Anki's `Cargo.lock` to the root
- [ ] 1.3 Add a Rust test that fails when the root `Cargo.lock` differs from `third_party/anki/Cargo.lock`

## 2. Bridge crate
- [ ] 2.1 Create `crates/rslib-bridge` (staticlib + lib) depending on `anki` by path, with `tokio` `io-util`; `cargo check --target aarch64-apple-ios -j2` passes
- [ ] 2.2 Implement `open_backend`, `close_backend` with tests for valid, invalid and null input
- [ ] 2.3 Find one trivial service/method index pair from rslib's generated code and record it in the test as a documented constant
- [ ] 2.4 Implement `run_method` and `free_bytes` with `catch_unwind`; tests for success, engine error (decodes as `BackendError`), unknown method, and freeing an empty buffer
- [ ] 2.5 Add `rslib_bridge.h` and a test that its declared functions match the exported symbols

## 3. Packaging
- [ ] 3.1 Write `scripts/build-xcframework.sh` (sets `PROTOC`, runs `setup-engine.sh`, builds both targets serially at `-j2`, creates the XCFramework in `build/`)
- [ ] 3.2 Run it; confirm the XCFramework has `ios-arm64` and `ios-arm64-simulator` slices and record size and peak build time in the ledger `finish` entry
- [ ] 3.3 Update README and `CLAUDE.md` layout/build notes with the setup and build commands

## 4. Verification
- [ ] 4.1 `cargo fmt --check`, `cargo clippy -D warnings`, `cargo test -j2` pass
- [ ] 4.2 `npm run gate` passes; ledger `finish` entry quotes the `GATE PASSED` line; push to `main`
