#!/usr/bin/env bash
# Builds the rslib bridge for iOS device and simulator and bundles both into
# build/RslibBridge.xcframework. Serial and -j2 on purpose: the dev machine has 8 GB of RAM.
# Override the job count with CARGO_JOBS=1 if the linker is killed.
set -euo pipefail
cd "$(dirname "$0")/.."

JOBS="${CARGO_JOBS:-2}"
export CARGO_BUILD_JOBS="$JOBS"
# The app targets iOS 26; without this rustc and the C dependencies default to the SDK version.
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-26.0}"
export PROTOC="${PROTOC:-$(command -v protoc || echo /opt/homebrew/bin/protoc)}"

scripts/setup-engine.sh

for target in aarch64-apple-ios aarch64-apple-ios-sim; do
  cargo build -p rslib-bridge --release --target "$target" -j "$JOBS"
done

HEADERS="build/headers"
rm -rf "$HEADERS" build/RslibBridge.xcframework
mkdir -p "$HEADERS"
cp crates/rslib-bridge/rslib_bridge.h "$HEADERS/"
cat > "$HEADERS/module.modulemap" <<'MAP'
module RslibBridge {
    header "rslib_bridge.h"
    export *
}
MAP

xcodebuild -create-xcframework \
  -library target/aarch64-apple-ios/release/librslib_bridge.a -headers "$HEADERS" \
  -library target/aarch64-apple-ios-sim/release/librslib_bridge.a -headers "$HEADERS" \
  -output build/RslibBridge.xcframework

echo "XCFramework: build/RslibBridge.xcframework"
du -sh build/RslibBridge.xcframework
