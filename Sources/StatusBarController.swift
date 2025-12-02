@preconcurrency import Cocoa
@preconcurrency import ApplicationServices

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem?
    private var eventTapManager: EventTapManager
    private var config: Config
    
    init(eventTapManager: EventTapManager, config: Config) {
        self.eventTapManager = eventTapManager
        self.config = config
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "uskey")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        updateMenu()
    }
    
    @objc private func statusBarButtonClicked() {
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "uskey - Keyboard Remapper", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let isEnabled = eventTapManager.isRunning()
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Enabled ✅" : "Enabled ❌",
            action: #selector(toggleMapping),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Current Mappings:", action: nil, keyEquivalent: ""))
        
        let mappings = config.mapping.getAllMappings()
        if mappings.isEmpty {
            let item = NSMenuItem(title: "  No mappings configured", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for (from, to) in mappings.sorted(by: { $0.0 < $1.0 }) {
                let item = NSMenuItem(title: "  \(from) → \(to)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let reloadItem = NSMenuItem(title: "Reload Configuration", action: #selector(reloadConfig), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openLogsItem = NSMenuItem(title: "Open Logs Folder", action: #selector(openLogsFolder), keyEquivalent: "l")
        openLogsItem.target = self
        menu.addItem(openLogsItem)
        
        if let _ = Logger.getLogFilePath() {
            let viewLogItem = NSMenuItem(title: "View Current Log", action: #selector(viewCurrentLog), keyEquivalent: "")
            viewLogItem.target = self
            menu.addItem(viewLogItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    @objc private func toggleMapping() {
        Logger.debug("Toggle mapping clicked, current state: \(eventTapManager.isRunning())")
        if eventTapManager.isRunning() {
            eventTapManager.stop()
            Logger.info("Mapping disabled by user")
        } else {
            Logger.info("Attempting to enable mapping...")
            if eventTapManager.start() {
                Logger.info("Mapping enabled by user")
            } else {
                Logger.error("Failed to enable mapping - check accessibility permissions")
                showAlert(title: "Error", message: "Failed to enable key mapping.\n\nPlease ensure:\n1. Accessibility permissions are granted\n2. The app is allowed in System Preferences > Privacy & Security > Accessibility\n\nCheck logs for details.")
            }
        }
        updateMenu()
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
    
    @objc private func openLogsFolder() {
        let logsDir = Logger.getLogsDirectory()
        Logger.info("Opening logs folder: \(logsDir)")
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: logsDir)
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
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}