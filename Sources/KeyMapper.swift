@preconcurrency import Foundation
@preconcurrency import CoreGraphics

struct KeyMapper {
    private var mappings: [Int64: (to: Int64, type: MappingType)] = [:]

    init() {
    }

    init(fromConfig config: Config) {
        loadFromConfig(config)
    }

    mutating func loadFromConfig(_ config: Config) {
        mappings.removeAll()
        for mapping in config.mapping.getAllMappings() {
            mappings[mapping.from] = (mapping.to, mapping.type)
            Logger.debug("Loaded mapping: \(mapping.from) -> \(mapping.to) (\(mapping.type.rawValue))")
        }
    }

    mutating func addMapping(from: Int64, to: Int64, type: MappingType = .keyboard) {
        mappings[from] = (to, type)
    }

    mutating func removeMapping(from: Int64) {
        mappings.removeValue(forKey: from)
    }

    func getMapping(for keyCode: Int64) -> (to: Int64, type: MappingType)? {
        return mappings[keyCode]
    }

    func hasMappingFor(keyCode: Int64) -> Bool {
        return mappings[keyCode] != nil
    }

    func printMappings() {
        Logger.info("")
        Logger.info("Current key mappings:")
        Logger.info("====================")
        for (from, value) in mappings.sorted(by: { $0.key < $1.key }) {
            Logger.info("  \(from) -> \(value.to) (\(value.type.rawValue))")
        }
        Logger.info("")
    }
}