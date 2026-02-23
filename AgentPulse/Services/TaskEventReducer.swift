import Foundation

struct TaskEventReducer {
    func reduce(
        existing: [String: UnifiedTask],
        events: [[String: Any]]
    ) -> [String: UnifiedTask] {
        var state = existing

        for event in events {
            guard let type = event["type"] as? String else { continue }

            if type == "queue-operation" {
                applyQueueOperation(event, state: &state)
                continue
            }

            if type == "agent_progress" {
                applyAgentProgress(event, state: &state)
            }
        }

        return state
    }

    private func applyQueueOperation(_ event: [String: Any], state: inout [String: UnifiedTask]) {
        let operation = ((event["operation"] as? String) ?? "").lowercased()
        let date = parseDate(event["timestamp"] as? String)

        switch operation {
        case "enqueue":
            guard let content = parseTaskContent(event["content"]) else {
                return
            }

            guard let taskID = content.taskId, !taskID.isEmpty else {
                return
            }

            state[taskID] = UnifiedTask(
                id: taskID,
                subject: content.description ?? "Unnamed task",
                status: .inProgress,
                owner: nil,
                updatedAt: date
            )

        case "remove", "dequeue":
            if let content = parseTaskContent(event["content"]), let taskID = content.taskId, var task = state[taskID] {
                task = UnifiedTask(
                    id: task.id,
                    subject: task.subject,
                    status: .completed,
                    owner: task.owner,
                    updatedAt: date
                )
                state[taskID] = task
                return
            }

            if let target = state.values
                .filter({ $0.status == .inProgress })
                .sorted(by: { $0.updatedAt > $1.updatedAt })
                .first {
                state[target.id] = UnifiedTask(
                    id: target.id,
                    subject: target.subject,
                    status: .completed,
                    owner: target.owner,
                    updatedAt: date
                )
            }

        case "popall":
            for (id, task) in state where task.status != .completed {
                state[id] = UnifiedTask(
                    id: task.id,
                    subject: task.subject,
                    status: .completed,
                    owner: task.owner,
                    updatedAt: date
                )
            }

        default:
            break
        }
    }

    private func applyAgentProgress(_ event: [String: Any], state: inout [String: UnifiedTask]) {
        guard let parentToolUseID = event["parentToolUseID"] as? String,
              var task = state[parentToolUseID] else {
            return
        }

        let prompt = event["prompt"] as? String
        task = UnifiedTask(
            id: task.id,
            subject: prompt ?? task.subject,
            status: .inProgress,
            owner: event["agentId"] as? String ?? task.owner,
            updatedAt: parseDate(event["timestamp"] as? String)
        )
        state[parentToolUseID] = task
    }

    private func parseTaskContent(_ raw: Any?) -> ClaudePendingTaskContent? {
        if let contentString = raw as? String {
            if contentString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }

            guard let data = contentString.data(using: .utf8) else {
                return nil
            }

            return try? JSONDecoder().decode(ClaudePendingTaskContent.self, from: data)
        }

        if let object = raw as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: object) {
            return try? JSONDecoder().decode(ClaudePendingTaskContent.self, from: data)
        }

        return nil
    }

    private func parseDate(_ timestamp: String?) -> Date {
        guard let timestamp else { return Date() }

        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: timestamp) {
            return date
        }

        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: timestamp) ?? Date()
    }
}
