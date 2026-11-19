#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/WeChatGroupManager.app/Contents/MacOS
swiftc -O -target arm64-apple-macos13.0 -framework SwiftUI -framework AppKit -framework ApplicationServices -o build/WeChatGroupManager.app/Contents/MacOS/WeChatGroupManager Sources/App.swift
cp Info.plist build/WeChatGroupManager.app/Contents/Info.plist
hdiutil create -volname WeChatGroupManager -srcfolder build/WeChatGroupManager.app -ov -format UDZO build/WeChatGroupManager-v1.2.dmg