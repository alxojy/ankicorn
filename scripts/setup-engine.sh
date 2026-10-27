#!/usr/bin/env bash
# Idempotent: checks out Anki at the pinned tag plus the two ftl submodules rslib's build script needs.
set -euo pipefail
cd "$(dirname "$0")/.."

git submodule update --init --depth 1 third_party/anki
cd third_party/anki
git submodule update --init --depth 1 ftl/core-repo ftl/qt-repo

# The submodule must sit on the tag the app is pinned to; fail loudly if it drifted.
tag="$(git fetch --depth 1 -q origin tag 26.09.3 && git rev-parse 26.09.3^{commit})"
[ "$(git rev-parse HEAD)" = "$tag" ] || { echo "third_party/anki is not at tag 26.09.3" >&2; exit 1; }
