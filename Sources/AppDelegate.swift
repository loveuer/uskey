@preconcurrency import Cocoa
@preconcurrency import ApplicationServices

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var eventTapManager: EventTapManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.setup()
        
        Logger.info("uskey - macOS Keyboard Remapper")
        Logger.info("================================")
        Logger.info("App bundle path: \(Bundle.main.bundlePath)")
        
        let config = loadConfig()
        Logger.logLevel = config.log.level
        
        let keyMapper = KeyMapper(fromConfig: config)
        keyMapper.printMappings()
        
        Logger.info("Checking accessibility permissions...")
        if !checkAccessibilityPermissions() {
            Logger.error("Accessibility permissions not granted!")
            showAccessibilityAlert()
            return
        }
        Logger.info("Accessibility permissions granted")
        
        eventTapManager = EventTapManager(keyMapper: keyMapper)
        statusBarController = StatusBarController(eventTapManager: eventTapManager!, config: config)
        
        statusBarController?.setupStatusBar()
        
        Logger.info("Attempting to start event monitoring...")
        if eventTapManager!.start() {
            Logger.info("Event monitoring started successfully")
        } else {
            Logger.error("Failed to start event monitoring - check if app has accessibility permissions")
        }
        
        Logger.info("Application ready")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        eventTapManager?.stop()
        Logger.info("Application terminated")
        Logger.cleanup()
    }
    
    private func loadConfig() -> Config {
        let configPath = Config.getConfigPath()
        Logger.info("Loading config from: \(configPath)")
        
        do {
            let config = try Config.load(from: configPath)
            Logger.info("Configuration loaded successfully")
            return config
        } catch {
            Logger.warning("Failed to load config: \(error.localizedDescription)")
            Logger.info("Creating default configuration...")
            
            do {
                try Config.createDefault(at: configPath)
                Logger.info("Default configuration created at: \(configPath)")
                return try Config.load(from: configPath)
            } catch {
                Logger.error("Failed to create default config: \(error.localizedDescription)")
                Logger.warning("Using fallback configuration")
                return Config()
            }
        }
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        Logger.debug("AXIsProcessTrusted result: \(trusted)")
        
        if !trusted {
            Logger.info("Requesting accessibility permissions...")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
        return trusted
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "uskey needs accessibility permissions to remap keyboard keys.\n\nPlease grant permissions in:\nSystem Preferences > Privacy & Security > Accessibility\n\nAfter granting permissions, restart the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}