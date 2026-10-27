## 1. Project and tooling
- [ ] 1.1 Add `app/project.yml` and generate `app/Cornhub.xcodeproj` with targets Cornhub, CornhubTests, CornhubUITests and a shared `Cornhub` scheme (iOS 26, Swift 6); link `build/RslibBridge.xcframework` and swift-protobuf
- [ ] 1.2 Add `scripts/bootstrap.sh` (engine setup, XCFramework only if missing, generators, XcodeGen) and make a clean `xcodebuild build` for the simulator pass with a placeholder app
- [ ] 1.3 Update README and CLAUDE.md with the bootstrap and test commands

## 2. Backend layer
- [ ] 2.1 Add `scripts/gen-swift-protos.sh`; commit generated Swift types; unit test that decodes a known message
- [ ] 2.2 Add `scripts/gen-service-index.mjs` (with `--check`) and the generated `ServiceIndex.swift`; unit test that each wrapped method's table entry reaches the intended method
- [ ] 2.3 Implement `Backend` (actor, handle lifecycle, generic typed call, buffer freeing) and `BackendError`; tests for success, engine error (`deck_tree` before open) and repeated open/close
- [ ] 2.4 Add wrappers `openCollection`, `closeCollection`, `addDeck`, `deckTree`; test that creates "HSK 1" and "HSK 2" in a temp collection and reads them back

## 3. App screen
- [ ] 3.1 Build the Phase 0 deck-tree screen (collection in Documents, `--seed-sample`, error state, accessibility labels, Dynamic Type) with previews at default and large text
- [ ] 3.2 UI test: launch with `--seed-sample`, assert the three decks are visible, attach screenshots at default and largest accessibility size; review the screenshots and note what was checked

## 4. Verification
- [ ] 4.1 `cargo fmt --check` and `xcodebuild test` (serial, `iPhone 17`) pass through `npm run verify`
- [ ] 4.2 `npm run gate` passes; ledger `finish` entry quotes it; push to `main`
