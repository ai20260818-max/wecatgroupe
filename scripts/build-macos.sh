#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/WeChatGroupManager.app"
rm -rf "$APP" build/dmg-root
mkdir -p "$APP/Contents/MacOS" build/dmg-root
SDK="$(xcrun --sdk macosx --show-sdk-path)"
xcrun swiftc -parse-as-library -O -sdk "$SDK" -target arm64-apple-macos13.0 \
  -framework SwiftUI -framework AppKit -framework ApplicationServices \
  -o "$APP/Contents/MacOS/WeChatGroupManager" Sources/App.swift
cp Info.plist "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/WeChatGroupManager"
codesign --force --deep --sign - "$APP"
cp -R "$APP" build/dmg-root/
cat > build/dmg-root/使用说明.txt <<'EOF'
微信群聊管理器 V1.2 — 只读原型
仅支持 Apple Silicon Mac，macOS 13 或以上。
当前仅有手动清单、保护标记、候选预览、CSV 导出及只读窗口检查。
微信 4.2 真实群聊扫描、共同群识别和退群尚未实现。
本应用为临时签名测试版，未经 Apple 公证。
将应用拖到 Applications 后打开；若系统阻止，可在系统设置的隐私与安全性中检查打开选项。
EOF
ln -s /Applications build/dmg-root/Applications
hdiutil create -volname WeChatGroupManager -srcfolder build/dmg-root -ov -format UDZO build/WeChatGroupManager-v1.2.dmg
hdiutil verify build/WeChatGroupManager-v1.2.dmg
shasum -a 256 build/WeChatGroupManager-v1.2.dmg > build/WeChatGroupManager-v1.2.dmg.sha256
