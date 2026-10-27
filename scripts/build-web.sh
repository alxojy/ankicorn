#!/usr/bin/env bash
# Builds Anki's SvelteKit pages (deck-options, card-info, graphs, ...) from the pinned checkout into
# app/Cornhub/Resources/AnkiWeb (gitignored). Replays the relevant steps of Anki's ninja build serially:
#   1. cargo build -p anki_proto -p anki_i18n   -> generated backend.ts and ftl.ts
#   2. protoc + protoc-gen-es + markpure.ts      -> generated *_pb.js
#   3. yarn build (vite, adapter-static)         -> out/sveltekit
# Runs in a scratch copy of the checkout: the repo's .cargo/config.toml clashes with Anki's when nested.
# Needs: node >= 20 with corepack, protoc (brew install protobuf), network for yarn. Skip with SKIP_WEB=1.
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
dest="$root/app/Cornhub/Resources/AnkiWeb"

if [ "${SKIP_WEB:-}" = 1 ]; then echo "SKIP_WEB=1, skipping web pages"; exit 0; fi
if [ -f "$dest/index.html" ] && [ "${FORCE_WEB:-}" != 1 ]; then echo "web pages present, skipping (FORCE_WEB=1 to rebuild)"; exit 0; fi

[ -d third_party/anki/ts ] || scripts/setup-engine.sh
work="${WEB_WORKDIR:-${TMPDIR:-/tmp}/ankicorn-web}"
mkdir -p "$work"
rsync -a --delete --exclude .git --exclude target --exclude out --exclude node_modules third_party/anki/ "$work/anki/"
cd "$work/anki"
mkdir -p out/rslib/proto out/ts/lib/generated

export PROTOC="${PROTOC:-$(command -v protoc)}" RUSTUP_TOOLCHAIN=stable CARGO_BUILD_JOBS=2
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NODE_OPTIONS=--max-old-space-size=3072

echo "== generated TS from rslib"
cargo build -j2 -p anki_proto -p anki_i18n

echo "== yarn install"
corepack yarn install --immutable
export PATH="$PWD/node_modules/.bin:$PATH"

echo "== protobuf TS"
protoc -I proto $(find proto -name '*.proto') --plugin=protoc-gen-es=node_modules/.bin/protoc-gen-es \
  --es_out out/ts/lib/generated
tsx ts/tools/markpure.ts out/ts/lib/generated
cp ts/lib/generated/*.ts out/ts/lib/generated/

echo "== sveltekit build"
corepack yarn build

rm -rf "$dest"
mkdir -p "$dest"
cp -R out/sveltekit/. "$dest/"
echo "web pages built: $(du -sh "$dest" | cut -f1) in app/Cornhub/Resources/AnkiWeb"
