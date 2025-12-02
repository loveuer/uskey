# Debugging Guide

## Log Files

uskey writes detailed logs to help diagnose issues.

### Log Location

- Directory: `~/.config/uskey/logs/`
- Current log: `uskey-YYYY-MM-DD.log` (one file per day)

### Accessing Logs

**Via Menu Bar:**
1. Click the uskey keyboard icon in the menu bar
2. Select "Open Logs Folder" (⌘L) - Opens Finder at log location
3. Select "View Current Log" - Opens today's log in default text editor

**Via Terminal:**
```bash
# View today's log
cat ~/.config/uskey/logs/uskey-$(date +%Y-%m-%d).log

# Follow log in real-time
tail -f ~/.config/uskey/logs/uskey-$(date +%Y-%m-%d).log
```

## Log Levels

Edit `~/.config/uskey/config.json` to change log level:

```json
{
  "log": {
    "level": "debug"
  }
}
```

Available levels (least to most verbose):
- **error** - Only errors
- **warning** - Warnings and errors
- **info** - General information (default)
- **debug** - Detailed debugging info including every key remap

After changing the level, select "Reload Configuration" (⌘R) from the menu.

## Common Debug Scenarios

### Mapping Not Enabling

1. Set log level to `debug`
2. Reload configuration
3. Try to enable mapping
4. Check logs for:
   ```
   [ERROR] Failed to create event tap
   [DEBUG] AXIsProcessTrusted result: false
   ```

If you see these errors:
- The app doesn't have accessibility permissions
- Go to System Preferences > Privacy & Security > Accessibility
- Add and enable uskey

### Keys Not Remapping

1. Set log level to `debug`
2. Press keys that should be remapped
3. Look for debug messages like:
   ```
   [DEBUG] Remapping: 42 -> 51
   ```

If you don't see these messages:
- Mapping is disabled (enable it from menu)
- Key code is not in your configuration
- Event tap is not working

### Configuration Issues

Check logs for:
```
[ERROR] Failed to load config: ...
[INFO] Creating default configuration...
```

This means the config file had issues and was recreated.

## Reporting Issues

When reporting issues, include:
1. macOS version
2. Log file with debug level enabled
3. Your config.json
4. Steps to reproduce

Example:
```bash
# Gather debug info
echo "=== System Info ===" > debug-info.txt
sw_vers >> debug-info.txt
echo -e "\n=== Config ===" >> debug-info.txt
cat ~/.config/uskey/config.json >> debug-info.txt
echo -e "\n=== Logs ===" >> debug-info.txt
cat ~/.config/uskey/logs/uskey-$(date +%Y-%m-%d).log >> debug-info.txt
```
