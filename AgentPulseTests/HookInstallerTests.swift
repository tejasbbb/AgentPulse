import Foundation
import XCTest
@testable import AgentPulse

final class HookInstallerTests: XCTestCase {
    func testInstallPreservesUnknownKeys() throws {
        let root = makeTempRoot()
        let settingsURL = root.appendingPathComponent("settings.json")

        let original: [String: Any] = [
            "model": "opus",
            "alwaysThinkingEnabled": true,
            "hooks": [
                "Stop": [[
                    "matcher": "",
                    "hooks": [["type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff"]]
                ]]
            ],
            "enabledPlugins": ["typescript-lsp@claude-plugins-official": true]
        ]

        let data = try JSONSerialization.data(withJSONObject: original, options: [.prettyPrinted])
        try data.write(to: settingsURL)

        let installer = HookInstaller(
            fileManager: .default,
            settingsURL: settingsURL,
            agentPulseRoot: root.appendingPathComponent(".agentpulse", isDirectory: true)
        )

        try installer.installHook()

        let newData = try Data(contentsOf: settingsURL)
        let object = try JSONSerialization.jsonObject(with: newData)
        let dict = try XCTUnwrap(object as? [String: Any])

        XCTAssertEqual(dict["model"] as? String, "opus")
        XCTAssertEqual(dict["alwaysThinkingEnabled"] as? Bool, true)

        let hooks = try XCTUnwrap(dict["hooks"] as? [String: Any])
        XCTAssertNotNil(hooks["Stop"])
        XCTAssertNotNil(hooks["PreToolUse"])
        XCTAssertTrue(installer.isHookInstalled())
    }

    func testUninstallRemovesOnlyAgentPulseHook() throws {
        let root = makeTempRoot()
        let settingsURL = root.appendingPathComponent("settings.json")

        let withHook: [String: Any] = [
            "hooks": [
                "Stop": [[
                    "matcher": "",
                    "hooks": [["type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff"]]
                ]],
                "PreToolUse": [[
                    "matcher": "",
                    "hooks": [
                        ["type": "command", "command": HookInstaller.hookCommand, "timeout": 120],
                        ["type": "command", "command": "echo keep-me", "timeout": 30]
                    ]
                ]]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: withHook, options: [.prettyPrinted])
        try data.write(to: settingsURL)

        let installer = HookInstaller(
            fileManager: .default,
            settingsURL: settingsURL,
            agentPulseRoot: root.appendingPathComponent(".agentpulse", isDirectory: true)
        )

        try installer.uninstallHook()

        let newData = try Data(contentsOf: settingsURL)
        let object = try JSONSerialization.jsonObject(with: newData)
        let dict = try XCTUnwrap(object as? [String: Any])
        let hooks = try XCTUnwrap(dict["hooks"] as? [String: Any])

        XCTAssertNotNil(hooks["Stop"])
        let preToolUse = try XCTUnwrap(hooks["PreToolUse"] as? [[String: Any]])
        let commandEntries = try XCTUnwrap(preToolUse.first?["hooks"] as? [[String: Any]])

        XCTAssertFalse(commandEntries.contains(where: { ($0["command"] as? String) == HookInstaller.hookCommand }))
        XCTAssertTrue(commandEntries.contains(where: { ($0["command"] as? String) == "echo keep-me" }))
    }

    private func makeTempRoot() -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hook-installer-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
