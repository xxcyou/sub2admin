#!/bin/bash
set -e
export PATH="/vol1/@appshare/DeepSeekHarness/workspace/flutter_env/flutter/bin:$PATH"
export ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk GRADLE_USER_HOME=/vol1/@appshare/DeepSeekHarness/workspace/gradle_home
rm -rf dist && mkdir -p dist
echo "=== build arm64-v8a ==="
flutter build apk --release --target-platform android-arm64 2>&1 | tail -2
cp build/app/outputs/flutter-apk/app-release.apk dist/sub2admin-v1.3.0-arm64-v8a.apk
echo "=== build armeabi-v7a ==="
flutter build apk --release --target-platform android-arm 2>&1 | tail -2
cp build/app/outputs/flutter-apk/app-release.apk dist/sub2admin-v1.3.0-armeabi-v7a.apk
echo "=== build x86_64 ==="
flutter build apk --release --target-platform android-x64 2>&1 | tail -2
cp build/app/outputs/flutter-apk/app-release.apk dist/sub2admin-v1.3.0-x86_64.apk
echo "=== build all ABIs (fat) ==="
flutter build apk --release 2>&1 | tail -2
cp build/app/outputs/flutter-apk/app-release.apk dist/sub2admin-v1.3.0-all.apk
echo "=== done ==="
ls -la dist
