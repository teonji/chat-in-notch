#!/bin/zsh
# Builds and assembles "Chat in Notch.app" (ad-hoc signed). Usage: ./build.sh [run]
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
BIN=$(swift build -c release --show-bin-path)/ChatInNotch
APP="build/Chat in Notch.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ChatInNotch"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/app-icon.png Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Creato $APP"
if [[ "${1:-}" == "run" ]]; then open "$APP"; fi
