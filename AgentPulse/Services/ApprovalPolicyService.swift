import Foundation

final class ApprovalPolicyService {
    private let fileManager: FileManager
    private let policyURL: URL

    init(fileManager: FileManager = .default, policyURL: URL? = nil) {
        self.fileManager = fileManager
        self.policyURL = policyURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".agentpulse", isDirectory: true)
            .appendingPathComponent("policy.json", isDirectory: false)
    }

    func loadPolicy() -> ApprovalPolicy {
        do {
            if !fileManager.fileExists(atPath: policyURL.path) {
                try persist(policy: .default)
                return .default
            }

            let data = try Data(contentsOf: policyURL)
            let decoder = JSONDecoder()
            return try decoder.decode(ApprovalPolicy.self, from: data)
        } catch {
            return .default
        }
    }

    func evaluate(toolName: String, toolInput: [String: AnyCodable], policy: ApprovalPolicy? = nil) -> PolicyEvaluation {
        let resolvedPolicy = policy ?? loadPolicy()

        if let rule = resolvedPolicy.toolRules[toolName] {
            return PolicyEvaluation(
                decision: rule.decision,
                riskLevel: rule.riskLevel,
                reason: reason(for: toolName, decision: rule.decision, riskLevel: rule.riskLevel, toolInput: toolInput)
            )
        }

        return PolicyEvaluation(
            decision: resolvedPolicy.defaultDecision,
            riskLevel: .high,
            reason: "Tool \(toolName) is not recognized; defaulting to \(resolvedPolicy.defaultDecision.rawValue)."
        )
    }

    func timeoutDecision(policy: ApprovalPolicy? = nil) -> ToolDecision {
        let resolvedPolicy = policy ?? loadPolicy()
        return resolvedPolicy.timeoutAction
    }

    private func reason(
        for toolName: String,
        decision: ToolDecision,
        riskLevel: ApprovalRiskLevel,
        toolInput: [String: AnyCodable]
    ) -> String {
        if let command = toolInput["command"]?.value.base as? String, toolName == "Bash" {
            return "Policy \(decision.rawValue) for Bash command '\(command)' (risk: \(riskLevel.rawValue))."
        }
        return "Policy \(decision.rawValue) for \(toolName) (risk: \(riskLevel.rawValue))."
    }

    private func persist(policy: ApprovalPolicy) throws {
        let dir = policyURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(policy)
        try data.write(to: policyURL, options: [.atomic])
    }
}
