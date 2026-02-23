import Foundation

enum ToolDecision: String, Codable {
    case allow
    case ask
    case deny
}

struct ToolPolicyRule: Codable {
    let decision: ToolDecision
    let riskLevel: ApprovalRiskLevel
}

struct ApprovalPolicy: Codable {
    let defaultDecision: ToolDecision
    let timeoutSeconds: Int
    let timeoutAction: ToolDecision
    let toolRules: [String: ToolPolicyRule]

    static let `default` = ApprovalPolicy(
        defaultDecision: .ask,
        timeoutSeconds: 115,
        timeoutAction: .deny,
        toolRules: [
            "Read": ToolPolicyRule(decision: .allow, riskLevel: .low),
            "Glob": ToolPolicyRule(decision: .allow, riskLevel: .low),
            "LS": ToolPolicyRule(decision: .allow, riskLevel: .low),
            "Bash": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "Write": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "Edit": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "MultiEdit": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "Delete": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "Move": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "Rename": ToolPolicyRule(decision: .ask, riskLevel: .high),
            "WebFetch": ToolPolicyRule(decision: .ask, riskLevel: .high)
        ]
    )
}

struct PolicyEvaluation {
    let decision: ToolDecision
    let riskLevel: ApprovalRiskLevel
    let reason: String
}
