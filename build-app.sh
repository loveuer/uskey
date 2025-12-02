#!/bin/bash
set -e

echo "Building uskey.app..."

APP_NAME="uskey"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_FILE="static/uskey.icns"

echo "Step 1: Building release binary..."
swift build -c release

echo "Step 2: Creating app icon (if needed)..."
if [ ! -f "$ICON_FILE" ]; then
    echo "  Icon not found, creating from PNG..."
    ./create-icon.sh
fi

echo "Step 3: Creating app bundle structure..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "Step 4: Copying binary..."
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

echo "Step 5: Copying icon..."
if [ -f "$ICON_FILE" ]; then
    cp "$ICON_FILE" "$RESOURCES_DIR/$APP_NAME.icns"
    echo "  Icon copied successfully"
else
    echo "  Warning: Icon file not found, skipping..."
fi

echo "Step 6: Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.uskey.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025. All rights reserved.</string>
</dict>
</plist>
EOF

echo "Step 7: Setting permissions..."
chmod +x "$MACOS_DIR/$APP_NAME"

echo ""
echo "✅ App bundle created at: $APP_DIR"
echo ""
echo "To create DMG, run: ./build-dmg.sh"