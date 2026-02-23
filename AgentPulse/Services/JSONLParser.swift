import Foundation

struct JSONLParseResult {
    let events: [[String: Any]]
    let newOffset: UInt64
    let wasTruncated: Bool
}

enum JSONLParserError: Error {
    case invalidFileSize
}

final class JSONLParser {
    func parseAppendedJSON(
        from fileURL: URL,
        offset: UInt64,
        maxLines: Int = 5000
    ) throws -> JSONLParseResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return JSONLParseResult(events: [], newOffset: 0, wasTruncated: false)
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        guard let fileSizeNumber = attrs[.size] as? NSNumber else {
            throw JSONLParserError.invalidFileSize
        }

        let fileSize = fileSizeNumber.uint64Value
        let wasTruncated = fileSize < offset
        let startOffset: UInt64 = wasTruncated ? 0 : offset

        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        try handle.seek(toOffset: startOffset)
        let data = try handle.readToEnd() ?? Data()

        let newOffset = startOffset + UInt64(data.count)
        guard !data.isEmpty else {
            return JSONLParseResult(events: [], newOffset: newOffset, wasTruncated: wasTruncated)
        }

        let raw = String(decoding: data, as: UTF8.self)
        var parsedEvents = raw
            .split(whereSeparator: \ .isNewline)
            .compactMap { line -> [String: Any]? in
                guard let lineData = line.data(using: .utf8) else { return nil }
                guard let object = try? JSONSerialization.jsonObject(with: lineData) else { return nil }
                return object as? [String: Any]
            }

        if parsedEvents.count > maxLines {
            parsedEvents = Array(parsedEvents.suffix(maxLines))
        }

        return JSONLParseResult(events: parsedEvents, newOffset: newOffset, wasTruncated: wasTruncated)
    }
}
