# uskey

A macOS utility for remapping keyboard keys.

## Features

- Remap any keyboard key to another key
- Lightweight and efficient
- Native macOS integration using CoreGraphics
- JSON-based configuration
- Configurable logging levels

## Requirements

- macOS 13.0+
- Swift 6.0+

## Installation

### Option 1: Download DMG (Recommended)

1. Download the latest `uskey-x.x.x.dmg` from releases
2. Open the DMG file
3. Drag `uskey.app` to the Applications folder
4. Launch from Applications or Spotlight
5. Grant Accessibility permissions when prompted

### Option 2: Build from Source

```bash
git clone <repository-url>
cd uskey
./build-app.sh && ./build-dmg.sh
```

The DMG will be created at `.build/release/uskey-1.0.0.dmg`

For detailed build instructions, see [BUILD.md](BUILD.md)

## Configuration

The configuration file is automatically created at `~/.config/uskey/config.json` on first run.

### Configuration Format

```json
{
  "log": {
    "level": "info"
  },
  "mapping": {
    "backslash2backspace": {
      "from": 42,
      "to": 51
    },
    "backspace2backslash": {
      "from": 51,
      "to": 42
    }
  }
}
```

### Log Levels

- `debug` - Detailed debugging information including every key remap
- `info` - General information messages (default)
- `warning` - Warning messages
- `error` - Error messages only

### Key Codes

Common macOS key codes:
- Backspace: 51
- Backslash `\`: 42
- Enter: 36
- Tab: 48
- Space: 49

You can add custom mappings by editing the config file and restarting the application.

## Usage

```bash
uskey
```

**Important:** On first run, you'll be prompted to grant Accessibility permissions in System Preferences > Privacy & Security > Accessibility.

## Troubleshooting

### Enable Mapping Doesn't Work

If you can't enable mapping after installation:

1. **Check Accessibility Permissions**
   - Open System Preferences > Privacy & Security > Accessibility
   - Ensure `uskey` is in the list and checked
   - If not, click the `+` button and add the app
   - After granting permissions, restart the app

2. **Check Logs**
   - Click the uskey menu bar icon
   - Select "Open Logs Folder" (⌘L)
   - Open the latest log file (e.g., `uskey-2025-12-02.log`)
   - Look for ERROR messages

3. **Enable Debug Logging**
   - Edit `~/.config/uskey/config.json`
   - Change `"level": "info"` to `"level": "debug"`
   - Click "Reload Configuration" (⌘R) in the menu
   - Try enabling mapping again
   - Check logs for detailed debug information

### Log Files Location

Logs are stored at: `~/.config/uskey/logs/uskey-YYYY-MM-DD.log`

You can view logs by:
- **Menu Bar**: Click uskey icon → "View Current Log"
- **Finder**: Click uskey icon → "Open Logs Folder" (⌘L)
- **Terminal**: `tail -f ~/.config/uskey/logs/uskey-$(date +%Y-%m-%d).log`

### Common Issues

**"Failed to create event tap"**
- Cause: Missing accessibility permissions
- Solution: Grant accessibility permissions and restart the app

**Configuration not found**
- Cause: Config file doesn't exist
- Solution: The app will auto-create it at `~/.config/uskey/config.json`

**Mapping not working**
- Cause: Event tap is not enabled
- Solution: Check logs and ensure accessibility permissions are granted

## Development

Build the project:
```bash
swift build
```

Run in debug mode:
```bash
swift run
```

## License

MIT