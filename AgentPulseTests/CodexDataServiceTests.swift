import XCTest
@testable import AgentPulse

final class CodexDataServiceTests: XCTestCase {
    func testParseConfigHandlesQuotedProjectSectionsAndFeatures() {
        let service = CodexDataService()

        let input = """
        model = "gpt-5.3-codex"
        personality = "pragmatic"

        [projects."/Users/tejasbhardwaj/Desktop/react-native-preschool"]
        trust_level = "untrusted"

        [features]
        steer = true
        collaboration_modes = true
        """

        let config = service.parseConfig(content: input)

        XCTAssertEqual(config.model, "gpt-5.3-codex")
        XCTAssertEqual(config.personality, "pragmatic")
        XCTAssertEqual(config.projectTrustLevels["/Users/tejasbhardwaj/Desktop/react-native-preschool"], "untrusted")
        XCTAssertEqual(config.features["steer"], true)
        XCTAssertEqual(config.features["collaboration_modes"], true)
    }
}
