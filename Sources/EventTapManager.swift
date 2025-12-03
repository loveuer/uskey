@preconcurrency import Cocoa
@preconcurrency import CoreGraphics
@preconcurrency import ApplicationServices

class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled: Bool = false
    var keyMapper: KeyMapper
    
    init(keyMapper: KeyMapper) {
        self.keyMapper = keyMapper
    }
    
    func start() -> Bool {
        guard !isEnabled else { return true }
        
        Logger.debug("Creating event tap...")
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard type == .keyDown || type == .keyUp else {
                return Unmanaged.passRetained(event)
            }
            
            guard let refcon = refcon else {
                Logger.error("Event callback: refcon is nil")
                return Unmanaged.passRetained(event)
            }
            
            let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
            
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            if manager.keyMapper.hasMappingFor(keyCode: keyCode) {
                if let mappedKey = manager.keyMapper.getMappedKey(for: keyCode) {
                    Logger.debug("Remapping: \(keyCode) -> \(mappedKey)")
                    
                    let newEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(mappedKey), keyDown: type == .keyDown)
                    if let newEvent = newEvent {
                        newEvent.flags = event.flags
                        newEvent.post(tap: .cghidEventTap)
                    }
                    
                    return nil
                }
            }
            
            return Unmanaged.passRetained(event)
        }
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPtr
        )
        
        guard let eventTap = eventTap else {
            Logger.error("Failed to create event tap - check accessibility permissions")
            return false
        }
        
        Logger.debug("Event tap created successfully")
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            Logger.error("Failed to create run loop source")
            return false
        }
        
        Logger.debug("Adding event tap to run loop...")
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isEnabled = true
        Logger.info("Event tap started")
        return true
    }
    
    func stop() {
        guard isEnabled else { return }
        
        Logger.debug("Stopping event tap...")
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        }
        
        eventTap = nil
        runLoopSource = nil
        isEnabled = false
        
        Logger.info("Event tap stopped")
    }
    
    func isRunning() -> Bool {
        return isEnabled
    }
    
    func reload(config: Config) {
        let wasEnabled = isEnabled
        if wasEnabled {
            stop()
        }
        
        keyMapper.loadFromConfig(config)
        
        if wasEnabled {
            _ = start()
        }
    }
}