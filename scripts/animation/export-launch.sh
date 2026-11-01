#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT="$ROOT/build/animation_launch"
mkdir -p "$OUTPUT"
# Render shared SwiftUI artwork offscreen, without Simulator or signing.
xcrun --sdk macosx swiftc \
    -parse-as-library -swift-version 5 \
    -target "$(uname -m)-apple-macosx13.0" \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    "$ROOT/SideStore/Views/SplashView.swift" \
    "$ROOT/scripts/animation/ExportLaunch.swift" \
    -o "$OUTPUT/export-launch"
"$OUTPUT/export-launch" "$OUTPUT"
test -s "$OUTPUT/animation_launch.mp4"
