#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/WeChatGroupManager.app"
mkdir -p "$APP/Contents/MacOS" build/dmg-root
SDK="$(xcrun --sdk macosx --show-sdk-path)"
xcrun swiftc -O -sdk "$SDK" -target arm64-apple-macos13.0 \
  -framework SwiftUI -framework AppKit -framework ApplicationServices \
  -o "$APP/Contents/MacOS/WeChatGroupManager" Sources/App.swift
cp Info.plist "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/WeChatGroupManager"
codesign --force --deep --sign - "$APP"
cp -R "$APP" build/dmg-root/
ln -s /Applications build/dmg-root/Applications
hdiutil create -volname WeChatGroupManager -srcfolder build/dmg-root -ov -format UDZO build/WeChatGroupManager-v1.2.dmg
hdiutil verify build/WeChatGroupManager-v1.2.dmg
