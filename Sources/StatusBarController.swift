@preconcurrency import Cocoa
@preconcurrency import ApplicationServices

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem?
    private var eventTapManager: EventTapManager
    private var config: Config
    private var menu: NSMenu?
    
    init(eventTapManager: EventTapManager, config: Config) {
        self.eventTapManager = eventTapManager
        self.config = config
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "uskey")
        }
        
        updateMenu()
    }
    
    @objc private func statusBarButtonClicked() {
        updateMenu()
    }
    
    private func updateMenu() {
        let newMenu = NSMenu()
        
        newMenu.addItem(NSMenuItem(title: "uskey - Keyboard Remapper", action: nil, keyEquivalent: ""))
        newMenu.addItem(NSMenuItem.separator())
        
        let isEnabled = eventTapManager.isRunning()
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Enabled ✅" : "Enabled ❌",
            action: #selector(toggleMapping),
            keyEquivalent: ""
        )
        toggleItem.target = self
        newMenu.addItem(toggleItem)
        
        newMenu.addItem(NSMenuItem.separator())
        newMenu.addItem(NSMenuItem(title: "Current Mappings:", action: nil, keyEquivalent: ""))
        
        let mappings = config.mapping.getAllMappings()
        if mappings.isEmpty {
            let item = NSMenuItem(title: "  No mappings configured", action: nil, keyEquivalent: "")
            item.isEnabled = false
            newMenu.addItem(item)
        } else {
            for (from, to) in mappings.sorted(by: { $0.0 < $1.0 }) {
                let item = NSMenuItem(title: "  \(from) → \(to)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                newMenu.addItem(item)
            }
        }
        
        newMenu.addItem(NSMenuItem.separator())
        
        let reloadItem = NSMenuItem(title: "Reload Configuration", action: #selector(reloadConfig), keyEquivalent: "r")
        reloadItem.target = self
        newMenu.addItem(reloadItem)
        
        newMenu.addItem(NSMenuItem.separator())
        
        let openConfigItem = NSMenuItem(title: "Open Config Folder", action: #selector(openConfigFolder), keyEquivalent: "c")
        openConfigItem.target = self
        newMenu.addItem(openConfigItem)
        
        if let _ = Logger.getLogFilePath() {
            let viewLogItem = NSMenuItem(title: "View Current Log", action: #selector(viewCurrentLog), keyEquivalent: "")
            viewLogItem.target = self
            newMenu.addItem(viewLogItem)
        }
        
        newMenu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "⚠️ About Limitations", action: #selector(showLimitations), keyEquivalent: "")
        aboutItem.target = self
        newMenu.addItem(aboutItem)
        
        newMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        newMenu.addItem(quitItem)
        
        self.menu = newMenu
        self.statusItem?.menu = newMenu
    }
    
    @objc private func toggleMapping() {
        Logger.debug("Toggle mapping clicked, current state: \(eventTapManager.isRunning())")
        if eventTapManager.isRunning() {
            eventTapManager.stop()
            Logger.info("Mapping disabled by user")
            saveEnabledState(false)
        } else {
            Logger.info("Attempting to enable mapping...")
            if eventTapManager.start() {
                Logger.info("Mapping enabled by user")
                saveEnabledState(true)
            } else {
                Logger.error("Failed to enable mapping - check accessibility permissions")
                showAlert(title: "Error", message: "Failed to enable key mapping.\n\nPlease ensure:\n1. Accessibility permissions are granted\n2. The app is allowed in System Preferences > Privacy & Security > Accessibility\n\nCheck logs for details.")
            }
        }
        updateMenu()
    }
    
    private func saveEnabledState(_ enabled: Bool) {
        do {
            let configPath = Config.getConfigPath()
            let updatedConfig = Config(log: config.log, mapping: config.mapping, enabled: enabled)
            try Config.save(updatedConfig, to: configPath)
            config = updatedConfig
            Logger.info("Saved enabled state: \(enabled)")
        } catch {
            Logger.error("Failed to save enabled state: \(error)")
        }
    }
    
    @objc private func reloadConfig() {
        Logger.info("Reloading configuration...")
        do {
            let configPath = Config.getConfigPath()
            config = try Config.load(from: configPath)
            Logger.logLevel = config.log.level
            eventTapManager.reload(config: config)
            Logger.info("Configuration reloaded successfully")
            updateMenu()
        } catch {
            Logger.error("Failed to reload configuration: \(error)")
            showAlert(title: "Error", message: "Failed to reload configuration: \(error.localizedDescription)")
        }
    }
    
    @objc private func openConfigFolder() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configDir = homeDir.appendingPathComponent(".config/uskey").path
        Logger.info("Opening config folder: \(configDir)")
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: configDir)
    }
    
    @objc private func viewCurrentLog() {
        if let logPath = Logger.getLogFilePath() {
            Logger.info("Opening log file: \(logPath)")
            NSWorkspace.shared.openFile(logPath)
        }
    }
    
    @objc private func quitApp() {
        Logger.info("Quitting application")
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func showLimitations() {
        let alert = NSAlert()
        alert.messageText = "Known Limitations"
        alert.informativeText = """
Due to macOS security restrictions, key remapping may not work in the following scenarios:

• Password input fields (Secure Input Mode)
• Lock screen / Login screen
• System dialogs and some secure contexts
• Some applications with enhanced security

This is a macOS system limitation that affects all third-party keyboard remapping tools.

For most regular input scenarios, remapping works as expected.
"""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}