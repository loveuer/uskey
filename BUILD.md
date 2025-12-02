# Build Scripts

This directory contains scripts to build and package uskey for distribution.

## Creating the App Icon

If you have a custom icon, place a 1024x1024 PNG file at `static/uskey.png`, then run:

```bash
./create-icon.sh
```

This will:
1. Create multiple icon sizes (16px to 1024px) for different display contexts
2. Generate a proper `.icns` file for macOS
3. Output to `static/uskey.icns`

The build script will automatically use this icon when building the app.

## Building the App Bundle

To create a macOS `.app` bundle:

```bash
./build-app.sh
```

This will:
1. Build the release binary using Swift Package Manager
2. Create a proper `.app` bundle structure
3. Add the `Info.plist` with app metadata
4. Copy the app icon to the bundle
5. Set the app to run as a menu bar utility (LSUIElement)

The resulting app will be at `.build/release/uskey.app`

## Creating a DMG Installer

To create a distributable DMG file:

```bash
./build-dmg.sh
```

This will:
1. Create a disk image with the app and Applications folder link
2. Configure the DMG appearance (icon layout)
3. Compress the DMG for distribution

The resulting DMG will be at `.build/release/uskey-1.0.0.dmg`

## One-Step Build

To build both the app and DMG:

```bash
./build-app.sh && ./build-dmg.sh
```

## Distribution

After building the DMG, you can distribute `uskey-1.0.0.dmg` to users. They can:

1. Open the DMG file
2. Drag `uskey.app` to the Applications folder
3. Launch from Applications or Spotlight
4. Grant Accessibility permissions when prompted

## Notes

- The app is built with `LSUIElement` set to `true`, so it runs as a menu bar-only app (no Dock icon)
- Minimum macOS version is set to 13.0
- Bundle identifier is `com.uskey.app`
- Icon is automatically included if `static/uskey.icns` exists