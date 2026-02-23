import Foundation
import XCTest
@testable import AgentPulse

final class JSONLParserTests: XCTestCase {
    func testParseAppendedReadsOnlyNewLines() throws {
        let fileURL = makeTempFile()
        try "{\"type\":\"one\"}\n{\"type\":\"two\"}\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let parser = JSONLParser()
        let first = try parser.parseAppendedJSON(from: fileURL, offset: 0)
        XCTAssertEqual(first.events.count, 2)

        let handle = try FileHandle(forWritingTo: fileURL)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("{\"type\":\"three\"}\n".utf8))
        try handle.close()

        let second = try parser.parseAppendedJSON(from: fileURL, offset: first.newOffset)
        XCTAssertEqual(second.events.count, 1)
        XCTAssertEqual(second.events.first?["type"] as? String, "three")
    }

    func testParseAppendedDetectsTruncate() throws {
        let fileURL = makeTempFile()
        try "{\"type\":\"one\"}\n{\"type\":\"two\"}\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let parser = JSONLParser()
        let first = try parser.parseAppendedJSON(from: fileURL, offset: 0)

        try "{\"type\":\"fresh\"}\n".write(to: fileURL, atomically: true, encoding: .utf8)
        let second = try parser.parseAppendedJSON(from: fileURL, offset: first.newOffset)

        XCTAssertTrue(second.wasTruncated)
        XCTAssertEqual(second.events.count, 1)
        XCTAssertEqual(second.events.first?["type"] as? String, "fresh")
    }

    private func makeTempFile() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("jsonl-parser-\(UUID().uuidString).jsonl")
    }
}
