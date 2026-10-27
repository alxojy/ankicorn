#!/usr/bin/env bash
# Generates Swift protobuf types from the pinned Anki submodule's .proto files into
# app/Cornhub/Backend/Generated/ (committed). Needs protoc and protoc-gen-swift (brew install swift-protobuf).
set -euo pipefail
cd "$(dirname "$0")/.."

proto_dir=third_party/anki/proto
out=app/Cornhub/Backend/Generated
[ -d "$proto_dir/anki" ] || { echo "run scripts/setup-engine.sh first" >&2; exit 1; }

rm -rf "$out"
mkdir -p "$out"
protoc \
  --proto_path="$proto_dir" \
  --swift_out="$out" \
  --swift_opt=FileNaming=PathToUnderscores,Visibility=Internal \
  "$proto_dir"/anki/*.proto
echo "generated $(ls "$out" | wc -l | tr -d ' ') files in $out"
