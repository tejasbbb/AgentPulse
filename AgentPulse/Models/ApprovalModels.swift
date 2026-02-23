import Foundation

enum ApprovalRiskLevel: String, Codable, CaseIterable {
    case high
    case medium
    case low
}

enum ApprovalDecision: String, Codable, CaseIterable {
    case allow
    case deny
    case ask
}

struct ApprovalRequest: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let source: String
    let sessionId: String
    let toolUseId: String
    let toolName: String
    let toolInput: [String: AnyCodable]
    let riskLevel: ApprovalRiskLevel
    let riskReason: String
    let timeoutSeconds: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case source
        case sessionId
        case toolUseId
        case toolName
        case toolInput
        case riskLevel
        case riskReason
        case timeoutSeconds
    }

    var displayType: String {
        toolName.uppercased()
    }

    var displayDetail: String {
        if let command = toolInput["command"]?.value.base as? String {
            return command
        }
        if let path = toolInput["file_path"]?.value.base as? String {
            return path
        }
        return toolInput.description
    }

    var elapsedSeconds: Int {
        max(0, Int(Date().timeIntervalSince(createdAt)))
    }
}

struct ApprovalResponse: Codable {
    let id: String
    let decision: ApprovalDecision
    let decisionReason: String
    let respondedAt: Date

    static func allow(id: String, reason: String = "Approved via AgentPulse") -> ApprovalResponse {
        ApprovalResponse(id: id, decision: .allow, decisionReason: reason, respondedAt: Date())
    }

    static func deny(id: String, reason: String = "Denied via AgentPulse") -> ApprovalResponse {
        ApprovalResponse(id: id, decision: .deny, decisionReason: reason, respondedAt: Date())
    }

    func toHookOutput() -> HookDecisionPayload {
        HookDecisionPayload(
            hookSpecificOutput: HookSpecificOutput(
                hookEventName: "PreToolUse",
                permissionDecision: decision.rawValue,
                permissionDecisionReason: decisionReason
            )
        )
    }
}

struct HookDecisionPayload: Codable {
    let hookSpecificOutput: HookSpecificOutput
}

struct HookSpecificOutput: Codable {
    let hookEventName: String
    let permissionDecision: String
    let permissionDecisionReason: String
}
