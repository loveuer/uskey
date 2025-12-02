@preconcurrency import Foundation
@preconcurrency import CoreGraphics

struct KeyMapper {
    private var mappings: [Int64: Int64] = [:]
    
    init() {
    }
    
    init(fromConfig config: Config) {
        loadFromConfig(config)
    }
    
    mutating func loadFromConfig(_ config: Config) {
        mappings.removeAll()
        for (from, to) in config.mapping.getAllMappings() {
            mappings[from] = to
            Logger.debug("Loaded mapping: \(from) -> \(to)")
        }
    }
    
    mutating func addMapping(from: Int64, to: Int64) {
        mappings[from] = to
    }
    
    mutating func removeMapping(from: Int64) {
        mappings.removeValue(forKey: from)
    }
    
    func getMappedKey(for keyCode: Int64) -> Int64? {
        return mappings[keyCode]
    }
    
    func hasMappingFor(keyCode: Int64) -> Bool {
        return mappings[keyCode] != nil
    }
    
    func printMappings() {
        Logger.info("")
        Logger.info("Current key mappings:")
        Logger.info("====================")
        for (from, to) in mappings.sorted(by: { $0.key < $1.key }) {
            Logger.info("  \(from) -> \(to)")
        }
        Logger.info("")
    }
}