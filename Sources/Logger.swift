@preconcurrency import Foundation

struct Logger {
    nonisolated(unsafe) static var logLevel: LogLevel = .info
    nonisolated(unsafe) private static var logFileHandle: FileHandle?
    nonisolated(unsafe) private static var logFilePath: String?
    
    static func setup() {
        let logsDir = getLogsDirectory()
        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: logsDir), withIntermediateDirectories: true)
        
        logFilePath = "\(logsDir)/uskey.log"
        
        FileManager.default.createFile(atPath: logFilePath!, contents: nil)
        
        logFileHandle = FileHandle(forWritingAtPath: logFilePath!)
        
        info("Logger initialized, log file: \(logFilePath!)")
    }
    
    static func getLogFilePath() -> String? {
        return logFilePath
    }
    
    static func getLogsDirectory() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/uskey/logs").path
    }
    
    static func debug(_ message: String) {
        log(.debug, message)
    }
    
    static func info(_ message: String) {
        log(.info, message)
    }
    
    static func warning(_ message: String) {
        log(.warning, message)
    }
    
    static func error(_ message: String) {
        log(.error, message)
    }
    
    private static func log(_ level: LogLevel, _ message: String) {
        guard logLevel.shouldLog(level) else { return }
        
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = formatter.string(from: timestamp)
        
        let levelString: String
        switch level {
        case .debug:
            levelString = "DEBUG"
        case .info:
            levelString = "INFO"
        case .warning:
            levelString = "WARN"
        case .error:
            levelString = "ERROR"
        }
        
        let logMessage = "[\(timeString)] [\(levelString)] \(message)\n"
        
        print(logMessage, terminator: "")
        
        if let data = logMessage.data(using: .utf8) {
            logFileHandle?.write(data)
        }
    }
    
    static func cleanup() {
        logFileHandle?.closeFile()
    }
}