import XCTest
@testable import AgentPulse

final class ApprovalPolicyServiceTests: XCTestCase {
    func testEvaluatesLowRiskReadAsAllow() {
        let service = makeService()
        let eval = service.evaluate(toolName: "Read", toolInput: [:], policy: .default)

        XCTAssertEqual(eval.decision, .allow)
        XCTAssertEqual(eval.riskLevel, .low)
    }

    func testEvaluatesUnknownToolAsAsk() {
        let service = makeService()
        let eval = service.evaluate(toolName: "MysteryTool", toolInput: [:], policy: .default)

        XCTAssertEqual(eval.decision, .ask)
        XCTAssertEqual(eval.riskLevel, .high)
    }

    func testTimeoutActionDefaultsToDeny() {
        let service = makeService()
        XCTAssertEqual(service.timeoutDecision(policy: .default), .deny)
    }

    private func makeService() -> ApprovalPolicyService {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("policy.json")
        return ApprovalPolicyService(fileManager: .default, policyURL: tmpURL)
    }
}
