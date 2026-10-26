#!/bin/zsh
# Creates dist/Chat-in-Notch.zip with the app built from scratch and ad-hoc signed.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
mkdir -p dist
rm -f dist/Chat-in-Notch.zip
ditto -c -k --keepParent "build/Chat in Notch.app" dist/Chat-in-Notch.zip
codesign --verify --deep --strict "build/Chat in Notch.app"
echo "Creato dist/Chat-in-Notch.zip"
