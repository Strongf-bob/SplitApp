import Foundation

extension KeyedDecodingContainer {
    func decodeLosslessDouble(forKey key: Key) throws -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }

        let stringValue = try decode(String.self, forKey: key)
        let normalized = stringValue.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Expected numeric string for \(key.stringValue)."
            )
        }
        return value
    }

    func decodeLosslessDoubleIfPresent(forKey key: Key) throws -> Double? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        return try decodeLosslessDouble(forKey: key)
    }
}
