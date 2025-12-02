#!/bin/bash
set -e

APP_NAME="uskey"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_DIR=".build/dmg"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_TEMP="$DMG_DIR/temp.dmg"
DMG_FINAL="$BUILD_DIR/$DMG_NAME"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: App bundle not found. Run ./build-app.sh first."
    exit 1
fi

echo "Creating DMG for $APP_NAME..."

echo "Step 1: Preparing DMG directory..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

echo "Step 2: Copying app to DMG directory..."
cp -R "$APP_DIR" "$DMG_DIR/"

echo "Step 3: Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

echo "Step 4: Creating temporary DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    "$DMG_TEMP"

echo "Step 5: Mounting temporary DMG..."
MOUNT_DIR=$(hdiutil attach "$DMG_TEMP" | grep Volumes | awk '{print $3}')

echo "Step 6: Setting DMG appearance..."
echo '
tell application "Finder"
    tell disk "'$APP_NAME'"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "'$APP_NAME'.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        update without registering applications
        delay 1
    end tell
end tell
' | osascript || true

echo "Step 7: Unmounting temporary DMG..."
hdiutil detach "$MOUNT_DIR" || true
sleep 2

echo "Step 8: Converting to compressed DMG..."
rm -f "$DMG_FINAL"
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

echo "Step 9: Cleaning up..."
rm -rf "$DMG_DIR"

echo ""
echo "✅ DMG created successfully!"
echo "   Location: $DMG_FINAL"
echo "   Size: $(du -h "$DMG_FINAL" | cut -f1)"
echo ""
echo "To install:"
echo "  1. Open $DMG_FINAL"
echo "  2. Drag $APP_NAME.app to Applications folder"
echo "  3. Run from Applications or Spotlight"
