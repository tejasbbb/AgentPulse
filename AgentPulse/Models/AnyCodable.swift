import Foundation

struct AnyCodable: Codable, Hashable {
    let value: AnyHashable

    init(_ value: AnyHashable) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = AnyHashable(intValue)
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            value = AnyHashable(doubleValue)
            return
        }

        if let boolValue = try? container.decode(Bool.self) {
            value = AnyHashable(boolValue)
            return
        }

        if let stringValue = try? container.decode(String.self) {
            value = AnyHashable(stringValue)
            return
        }

        if container.decodeNil() {
            value = AnyHashable(NSNull())
            return
        }

        if let arrayValue = try? container.decode([AnyCodable].self) {
            value = AnyHashable(arrayValue)
            return
        }

        if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            value = AnyHashable(dictionaryValue)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported JSON type for AnyCodable"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value.base {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case _ as NSNull:
            try container.encodeNil()
        case let arrayValue as [AnyCodable]:
            try container.encode(arrayValue)
        case let dictionaryValue as [String: AnyCodable]:
            try container.encode(dictionaryValue)
        default:
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Unsupported value for AnyCodable: \(value)"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
