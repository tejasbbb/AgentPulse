import Foundation

final class HookInstaller {
    static let hookCommand = "~/.agentpulse/hooks/approval-bridge.sh"

    private let fileManager: FileManager
    private let settingsURL: URL
    private let agentPulseRoot: URL

    init(
        fileManager: FileManager = .default,
        settingsURL: URL? = nil,
        agentPulseRoot: URL? = nil
    ) {
        self.fileManager = fileManager
        self.settingsURL = settingsURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude", isDirectory: true)
            .appendingPathComponent("settings.json", isDirectory: false)

        self.agentPulseRoot = agentPulseRoot
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".agentpulse", isDirectory: true)
    }

    func isHookInstalled() -> Bool {
        guard let dict = try? loadSettingsDictionary() else {
            return false
        }
        return containsHook(in: dict)
    }

    func installHook() throws {
        try ensureAgentPulseDirectories()
        try installHookScriptIfAvailable()

        var settings = try loadSettingsDictionaryIfExists() ?? [:]
        if containsHook(in: settings) {
            return
        }

        try backupCurrentSettingsIfExists()
        mergeHook(into: &settings)
        try write(settings: settings)
    }

    func uninstallHook() throws {
        guard var settings = try loadSettingsDictionaryIfExists() else {
            return
        }

        try backupCurrentSettingsIfExists()
        removeHook(from: &settings)
        try write(settings: settings)
    }

    private func ensureAgentPulseDirectories() throws {
        let pending = agentPulseRoot.appendingPathComponent("pending", isDirectory: true)
        let responses = agentPulseRoot.appendingPathComponent("responses", isDirectory: true)
        let hooks = agentPulseRoot.appendingPathComponent("hooks", isDirectory: true)

        try fileManager.createDirectory(at: pending, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: responses, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: hooks, withIntermediateDirectories: true)
    }

    private func installHookScriptIfAvailable() throws {
        let destination = agentPulseRoot
            .appendingPathComponent("hooks", isDirectory: true)
            .appendingPathComponent("approval-bridge.sh", isDirectory: false)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
            return
        }

        let candidateURLs: [URL?] = [
            Bundle.main.url(forResource: "approval-bridge", withExtension: "sh", subdirectory: "hooks"),
            Bundle.main.url(forResource: "approval-bridge", withExtension: "sh")
        ]

        if let sourceURL = candidateURLs.compactMap({ $0 }).first {
            let data = try Data(contentsOf: sourceURL)
            try data.write(to: destination, options: [.atomic])
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
        }
    }

    private func loadSettingsDictionaryIfExists() throws -> [String: Any]? {
        if !fileManager.fileExists(atPath: settingsURL.path) {
            return nil
        }
        return try loadSettingsDictionary()
    }

    private func loadSettingsDictionary() throws -> [String: Any] {
        let data = try Data(contentsOf: settingsURL)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dict = object as? [String: Any] else {
            throw NSError(domain: "HookInstaller", code: 1, userInfo: [NSLocalizedDescriptionKey: "settings.json root is not an object"])
        }
        return dict
    }

    private func write(settings: [String: Any]) throws {
        let parent = settingsURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)

        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: settingsURL, options: [.atomic])
    }

    private func backupCurrentSettingsIfExists() throws {
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            return
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")

        let backupURL = settingsURL
            .deletingLastPathComponent()
            .appendingPathComponent("settings.agentpulse.backup.\(stamp).json", isDirectory: false)

        let originalData = try Data(contentsOf: settingsURL)
        try originalData.write(to: backupURL, options: [.atomic])
    }

    private func containsHook(in settings: [String: Any]) -> Bool {
        guard let hooks = settings["hooks"] as? [String: Any],
              let preToolUse = hooks["PreToolUse"] as? [[String: Any]] else {
            return false
        }

        for group in preToolUse {
            guard let groupHooks = group["hooks"] as? [[String: Any]] else { continue }
            if groupHooks.contains(where: { ($0["command"] as? String) == Self.hookCommand }) {
                return true
            }
        }

        return false
    }

    private func mergeHook(into settings: inout [String: Any]) {
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        var preToolUse = hooks["PreToolUse"] as? [[String: Any]] ?? []

        var targetIndex: Int?
        for (index, group) in preToolUse.enumerated() {
            if (group["matcher"] as? String) == "" {
                targetIndex = index
                break
            }
        }

        if targetIndex == nil {
            preToolUse.append(["matcher": "", "hooks": [[String: Any]]()])
            targetIndex = preToolUse.indices.last
        }

        guard let index = targetIndex else { return }
        var targetGroup = preToolUse[index]
        var commands = targetGroup["hooks"] as? [[String: Any]] ?? []

        let exists = commands.contains { entry in
            (entry["command"] as? String) == Self.hookCommand
        }

        if !exists {
            commands.append([
                "type": "command",
                "command": Self.hookCommand,
                "timeout": 120
            ])
        }

        targetGroup["hooks"] = commands
        preToolUse[index] = targetGroup
        hooks["PreToolUse"] = preToolUse
        settings["hooks"] = hooks
    }

    private func removeHook(from settings: inout [String: Any]) {
        guard var hooks = settings["hooks"] as? [String: Any],
              var preToolUse = hooks["PreToolUse"] as? [[String: Any]] else {
            return
        }

        preToolUse = preToolUse.compactMap { group in
            var next = group
            let commands = (next["hooks"] as? [[String: Any]] ?? []).filter {
                ($0["command"] as? String) != Self.hookCommand
            }

            if commands.isEmpty {
                return nil
            }

            next["hooks"] = commands
            return next
        }

        if preToolUse.isEmpty {
            hooks.removeValue(forKey: "PreToolUse")
        } else {
            hooks["PreToolUse"] = preToolUse
        }

        if hooks.isEmpty {
            settings.removeValue(forKey: "hooks")
        } else {
            settings["hooks"] = hooks
        }
    }
}
