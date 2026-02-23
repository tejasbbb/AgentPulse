import Foundation
import XCTest
@testable import AgentPulse

final class ReducerTests: XCTestCase {
    func testQueueReducerHandlesEnqueueAndRemove() {
        let reducer = TaskEventReducer()

        let enqueue: [String: Any] = [
            "type": "queue-operation",
            "operation": "enqueue",
            "timestamp": "2026-02-22T08:25:00.610Z",
            "content": "{\"task_id\":\"abc\",\"description\":\"Run tests\",\"task_type\":\"local_agent\"}"
        ]

        let remove: [String: Any] = [
            "type": "queue-operation",
            "operation": "remove",
            "timestamp": "2026-02-22T08:26:00.610Z"
        ]

        let state1 = reducer.reduce(existing: [:], events: [enqueue])
        XCTAssertEqual(state1["abc"]?.status, .inProgress)

        let state2 = reducer.reduce(existing: state1, events: [remove])
        XCTAssertEqual(state2["abc"]?.status, .completed)
    }

    func testQueueReducerHandlesPopAll() {
        let reducer = TaskEventReducer()

        let existing: [String: UnifiedTask] = [
            "a": UnifiedTask(id: "a", subject: "A", status: .inProgress, owner: nil, updatedAt: Date()),
            "b": UnifiedTask(id: "b", subject: "B", status: .pending, owner: nil, updatedAt: Date())
        ]

        let popAll: [String: Any] = [
            "type": "queue-operation",
            "operation": "popAll",
            "timestamp": "2026-02-22T08:26:00.610Z"
        ]

        let reduced = reducer.reduce(existing: existing, events: [popAll])
        XCTAssertEqual(reduced["a"]?.status, .completed)
        XCTAssertEqual(reduced["b"]?.status, .completed)
    }

    func testFileReducerParsesBackupTimes() {
        let reducer = FileActivityReducer()

        let event: [String: Any] = [
            "type": "file-history-snapshot",
            "snapshot": [
                "timestamp": "2026-02-22T08:24:34.168Z",
                "trackedFileBackups": [
                    "/tmp/a.swift": ["backupTime": "2026-02-22T08:24:40.168Z"],
                    "/tmp/b.swift": ["backupTime": "2026-02-22T08:24:41.168Z"]
                ]
            ]
        ]

        let reduced = reducer.reduce(existing: [:], events: [event])
        XCTAssertEqual(reduced.count, 2)
        XCTAssertNotNil(reduced["/tmp/a.swift"])
    }
}
