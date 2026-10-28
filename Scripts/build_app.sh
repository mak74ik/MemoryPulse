#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🚀 Сборка MemoryPulse (Release)..."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

swift build -c release

APP_NAME="MemoryPulse"
BUNDLE_DIR="$DIR/build/${APP_NAME}.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Создание macOS App Bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$DIR/.build/release/MemoryPulse" "$MACOS_DIR/MemoryPulse"
chmod +x "$MACOS_DIR/MemoryPulse"

# Copy Info.plist and Icon
cp "$DIR/Sources/MemoryPulse/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$DIR/Sources/MemoryPulse/Resources/AppIcon.icns" ]; then
    cp "$DIR/Sources/MemoryPulse/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Ad-hoc codesign
echo "🔏 Подпись приложения (Ad-hoc codesign)..."
codesign --force --deep --sign - "$BUNDLE_DIR"

# Install into /Applications
echo "📥 Установка в /Applications..."
killall MemoryPulse 2>/dev/null || true
sleep 0.5
rm -rf "/Applications/${APP_NAME}.app"
cp -R "$BUNDLE_DIR" "/Applications/${APP_NAME}.app"

# Register in LaunchServices so Launchpad & Spotlight immediately pick it up
echo "🔄 Регистрация в LaunchServices и Launchpad..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/${APP_NAME}.app"

echo "✅ Приложение успешно установлено в /Applications/${APP_NAME}.app!"
