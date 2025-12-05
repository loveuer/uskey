@preconcurrency import Foundation

enum LogLevel: String, Codable {
    case debug
    case info
    case warning
    case error
    
    func shouldLog(_ level: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .warning, .error]
        guard let currentIndex = levels.firstIndex(of: self),
              let targetIndex = levels.firstIndex(of: level) else {
            return false
        }
        return targetIndex >= currentIndex
    }
}

struct LogConfig: Codable {
    let level: LogLevel
    
    init(level: LogLevel = .info) {
        self.level = level
    }
}

struct KeyMapping: Codable {
    let from: Int64
    let to: Int64
}

struct MappingConfig: Codable {
    private let mappings: [String: KeyMapping]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        mappings = try container.decode([String: KeyMapping].self)
    }
    
    init(mappings: [String: KeyMapping] = [:]) {
        self.mappings = mappings
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(mappings)
    }
    
    func getAllMappings() -> [(Int64, Int64)] {
        return mappings.values.map { ($0.from, $0.to) }
    }
}

struct Config: Codable {
    let log: LogConfig
    let mapping: MappingConfig
    let enabled: Bool
    
    init(log: LogConfig = LogConfig(), mapping: MappingConfig = MappingConfig(), enabled: Bool = true) {
        self.log = log
        self.mapping = mapping
        self.enabled = enabled
    }
    
    static func load(from path: String) throws -> Config {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Config.self, from: data)
    }
    
    static func save(_ config: Config, to path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: URL(fileURLWithPath: path))
    }
    
    static func createDefault(at path: String) throws {
        let defaultConfig = Config(
            log: LogConfig(level: .info),
            mapping: MappingConfig(mappings: [
                "backslash2backspace": KeyMapping(from: 42, to: 51),
                "backspace2backslash": KeyMapping(from: 51, to: 42)
            ]),
            enabled: true
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(defaultConfig)
        try data.write(to: URL(fileURLWithPath: path))
    }
    
    static func getConfigPath() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configDir = homeDir.appendingPathComponent(".config/uskey")
        
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        
        return configDir.appendingPathComponent("config.json").path
    }
}