## Decisions
- The Anki build system (ninja) is not used. Its steps are replayed: `cargo build -p anki_proto -p anki_i18n` writes `backend.ts` and `ftl.ts`, `protoc-gen-es` plus `markpure.ts` write the `*_pb.js` files, then `yarn build` (vite, adapter-static) writes `out/sveltekit`. This runs in a scratch copy of the checkout because the repo's `.cargo/config.toml` clashes with Anki's when nested.
- Pages are served as `cornhub-web://app/<route>#night`; unknown paths fall back to `index.html` (SvelteKit SPA fallback).
- A method name in the URL (`getDeckConfigsForUpdate`) maps to `(service, method)` through `ServiceIndex.methods`, generated from the same rslib source as the existing indices. Only the allow-list from mediasrv.py's `exposed_backend_list` is forwarded.
- Desktop-only endpoints (`deckOptionsReady`, `deckOptionsRequireClose`, `openLink`, profile/meta JSON) are handled in Swift; pickers, clipboard and add-on endpoints answer 501.
