import Foundation

struct CodexHistoryEntry: Codable {
    let sessionId: String
    let ts: Int64
    let text: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case ts
        case text
    }
}

struct CodexConfig {
    var model: String?
    var personality: String?
    var projectTrustLevels: [String: String]
    var features: [String: Bool]

    static let empty = CodexConfig(
        model: nil,
        personality: nil,
        projectTrustLevels: [:],
        features: [:]
    )
}

struct CodexGlobalState {
    var activeWorkspaceRoots: [String]
    var savedWorkspaceRoots: [String]
    var agentMode: String?
    var threadTitles: [String: String]

    static let empty = CodexGlobalState(
        activeWorkspaceRoots: [],
        savedWorkspaceRoots: [],
        agentMode: nil,
        threadTitles: [:]
    )
}
