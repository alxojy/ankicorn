#!/usr/bin/env bash
# One command from a fresh clone to a buildable Xcode project. Serial on purpose (8 GB RAM).
# Needs: xcodegen, protoc, protoc-gen-swift (brew install xcodegen protobuf swift-protobuf).
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n== %s\n' "$1"; }

step "engine checkout"
scripts/setup-engine.sh

if [ ! -d build/RslibBridge.xcframework ]; then
  step "XCFramework (missing, building; slow)"
  scripts/build-xcframework.sh
else
  step "XCFramework present, skipping"
fi

step "Swift protobuf types"
scripts/gen-swift-protos.sh

step "service index"
node scripts/gen-service-index.mjs

step "Xcode project"
xcodegen generate --spec app/project.yml --project app
echo "done: open app/Cornhub.xcodeproj or run npm run verify"
