#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT="$ROOT/build/animation_launch"
APP="$OUTPUT/LaunchPreview.app"
BUNDLE_ID="com.glitchfling.UltraStore.LaunchPreview"
mkdir -p "$APP"

# Use the installed iOS runtime and an iPhone supported by that runtime.
SIMULATOR_UDID="$(python3 - <<'PY'
import json
import subprocess

devices = json.loads(subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "--json"]
))["devices"]
for runtime, candidates in reversed(list(devices.items())):
    if ".iOS-" not in runtime:
        continue
    iphones = [d for d in candidates if d["name"].startswith("iPhone")]
    if iphones:
        print(iphones[0]["udid"])
        break
else:
    raise SystemExit("No available iPhone Simulator. Install an iOS runtime in Xcode.")
PY
)"

RECORDER_PID=""
cleanup() {
    if [ -n "$RECORDER_PID" ] && kill -0 "$RECORDER_PID" 2>/dev/null; then
        kill -INT "$RECORDER_PID"
        wait "$RECORDER_PID" || true
    fi
    xcrun simctl shutdown "$SIMULATOR_UDID" || true
}
trap cleanup EXIT

xcrun simctl boot "$SIMULATOR_UDID" || xcrun simctl bootstatus "$SIMULATOR_UDID" -b
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
ARCH="$(uname -m)"
xcrun --sdk iphonesimulator swiftc \
    -parse-as-library -swift-version 5 \
    -target "$ARCH-apple-ios17.0-simulator" -sdk "$SDK" \
    "$ROOT/SideStore/Views/SplashView.swift" \
    "$ROOT/scripts/animation/LaunchPreview.swift" \
    -o "$APP/LaunchPreview"

export APP BUNDLE_ID
python3 - <<'PY'
import os
import plistlib
from pathlib import Path

with (Path(os.environ["APP"]) / "Info.plist").open("wb") as output:
    plistlib.dump({
        "CFBundleIdentifier": os.environ["BUNDLE_ID"],
        "CFBundleExecutable": "LaunchPreview",
        "CFBundleName": "UltraStore Preview",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
        "MinimumOSVersion": "17.0",
        "LSRequiresIPhoneOS": True,
        "UIDeviceFamily": [1],
        "UILaunchScreen": {},
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
    }, output)
PY
codesign --force --sign - "$APP"
xcrun simctl install "$SIMULATOR_UDID" "$APP"

# The real view observes Reduce Motion; record its normal animated path.
xcrun simctl spawn "$SIMULATOR_UDID" defaults write com.apple.Accessibility ReduceMotionEnabled -bool false
xcrun simctl status_bar "$SIMULATOR_UDID" override --time '9:41' --batteryState charged --batteryLevel 100
xcrun simctl io "$SIMULATOR_UDID" recordVideo --codec h264 --force "$OUTPUT/animation_launch.mp4" \
    > "$OUTPUT/recording.log" 2>&1 &
RECORDER_PID=$!
sleep 2
kill -0 "$RECORDER_PID"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"
sleep 8
xcrun simctl io "$SIMULATOR_UDID" screenshot "$OUTPUT/final-frame.png"
kill -INT "$RECORDER_PID"
wait "$RECORDER_PID"
RECORDER_PID=""
test -s "$OUTPUT/animation_launch.mp4"
echo "Exported $OUTPUT/animation_launch.mp4"
