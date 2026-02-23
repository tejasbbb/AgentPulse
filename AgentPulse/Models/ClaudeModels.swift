import Foundation

struct ClaudeTeamConfig: Codable {
    let name: String
    let description: String?
    let createdAt: Int64?
    let leadAgentId: String?
    let members: [ClaudeTeamMember]
}

struct ClaudeTeamMember: Codable, Identifiable {
    let agentId: String
    let name: String
    let agentType: String?
    let model: String?
    let cwd: String?
    let joinedAt: Int64?

    var id: String { agentId }
}

struct ClaudeHistoryEntry: Codable {
    let display: String?
    let timestamp: Int64?
    let project: String?
    let sessionId: String?
}

struct ClaudeStatsCache: Codable {
    let version: Int?
    let lastComputedDate: String?
    let dailyActivity: [ClaudeDailyActivity]?
    let modelUsage: [String: ClaudeModelUsage]?
    let totalSessions: Int?
    let totalMessages: Int?
}

struct ClaudeDailyActivity: Codable {
    let date: String
    let messageCount: Int
    let sessionCount: Int
    let toolCallCount: Int
}

struct ClaudeModelUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheReadInputTokens: Int?
    let cacheCreationInputTokens: Int?
    let costUSD: Double?
}

struct ClaudePendingTaskContent: Codable {
    let taskId: String?
    let toolUseId: String?
    let description: String?
    let taskType: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case toolUseId = "tool_use_id"
        case description
        case taskType = "task_type"
    }
}

struct ClaudeQueueOperationEnvelope: Codable {
    let type: String
    let operation: String
    let timestamp: String?
    let sessionId: String?
    let content: String?
}

struct ClaudeAgentProgressEnvelope: Codable {
    let type: String
    let timestamp: String?
    let data: ClaudeAgentProgressData?
}

struct ClaudeAgentProgressData: Codable {
    let type: String?
    let agentId: String?
    let prompt: String?
}

struct ClaudeFileSnapshotEnvelope: Codable {
    let type: String
    let messageId: String?
    let snapshot: ClaudeFileSnapshot?
}

struct ClaudeFileSnapshot: Codable {
    let timestamp: String?
    let trackedFileBackups: [String: ClaudeTrackedFileBackup]?
}

struct ClaudeTrackedFileBackup: Codable {
    let backupFileName: String?
    let version: Int?
    let backupTime: String?
}
