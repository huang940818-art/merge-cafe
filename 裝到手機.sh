#!/bin/zsh
# 手機要解鎖、跟 Mac 同一個 Wi-Fi 或插線。改了 index.html 跑這支就會更新 App。
set -e
cd "$(dirname "$0")"
PHONE=00008150-00141DDC22F3401C
cp index.html icon.svg App/Cafe/web/
cd App
xcodegen generate -q
xcodebuild -project MergeCafe.xcodeproj -scheme MergeCafe -configuration Release \
  -destination "platform=iOS,id=$PHONE" -derivedDataPath build -allowProvisioningUpdates -allowProvisioningDeviceRegistration build | grep -E "error|BUILD|regist"
xcrun devicectl device install app --device $PHONE build/Build/Products/Release-iphoneos/MergeCafe.app
