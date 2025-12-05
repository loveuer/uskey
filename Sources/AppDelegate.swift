@preconcurrency import Cocoa
@preconcurrency import ApplicationServices

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var eventTapManager: EventTapManager?
    private var config: Config?
    private var keyMapper: KeyMapper?
    private var permissionCheckTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.setup()
        
        Logger.info("uskey - macOS Keyboard Remapper")
        Logger.info("================================")
        Logger.info("App bundle path: \(Bundle.main.bundlePath)")
        
        config = loadConfig()
        Logger.logLevel = config!.log.level
        
        Logger.info("Checking accessibility permissions...")
        if !checkAccessibilityPermissions() {
            Logger.warning("Accessibility permissions not granted, waiting for user to grant permissions...")
            showAccessibilityAlert()
            startPermissionMonitoring()
            return
        }
        
        Logger.info("Accessibility permissions granted")
        initializeApp()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        permissionCheckTimer?.invalidate()
        eventTapManager?.stop()
        Logger.info("Application terminated")
        Logger.cleanup()
    }
    
    private func initializeApp() {
        guard let config = config else {
            Logger.error("Configuration not loaded")
            return
        }
        
        let keyMapper = KeyMapper(fromConfig: config)
        self.keyMapper = keyMapper
        keyMapper.printMappings()
        
        eventTapManager = EventTapManager(keyMapper: keyMapper)
        statusBarController = StatusBarController(eventTapManager: eventTapManager!, config: config)
        
        statusBarController?.setupStatusBar()
        
        if config.enabled {
            Logger.info("Auto-enabling event monitoring (enabled: true in config)...")
            if eventTapManager!.start() {
                Logger.info("Event monitoring started successfully")
            } else {
                Logger.error("Failed to start event monitoring - check if app has accessibility permissions")
            }
        } else {
            Logger.info("Event monitoring not auto-enabled (enabled: false in config)")
        }
        
        Logger.info("Application ready")
    }
    
    private func startPermissionMonitoring() {
        Logger.info("Starting permission monitoring...")
        
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                let trusted = AXIsProcessTrusted()
                if trusted {
                    Logger.info("Accessibility permissions granted! Initializing app...")
                    self.permissionCheckTimer?.invalidate()
                    self.permissionCheckTimer = nil
                    self.initializeApp()
                }
            }
        }
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
        alert.informativeText = "uskey needs accessibility permissions to remap keyboard keys.\n\nPlease:\n1. Click 'Open System Preferences' in the dialog that appeared\n2. Enable uskey in the Accessibility list\n\nThe app will automatically start once permissions are granted."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        DispatchQueue.main.async {
            alert.runModal()
        }
    }
}