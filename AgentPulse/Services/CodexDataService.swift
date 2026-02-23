import Foundation

final class CodexDataService {
    private let fileManager: FileManager
    private let rootURL: URL

    init(fileManager: FileManager = .default, rootURL: URL? = nil) {
        self.fileManager = fileManager
        self.rootURL = rootURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
    }

    func loadGlobalState() -> CodexGlobalState {
        let url = rootURL.appendingPathComponent(".codex-global-state.json", isDirectory: false)
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .empty
        }

        let activeRoots = object["active-workspace-roots"] as? [String] ?? []
        let savedRoots = object["electron-saved-workspace-roots"] as? [String] ?? []

        var agentMode: String?
        if let atom = object["electron-persisted-atom-state"] as? [String: Any] {
            agentMode = atom["agent-mode"] as? String
        }

        var titles: [String: String] = [:]
        if let titleRoot = object["thread-titles"] as? [String: Any],
           let rawTitles = titleRoot["titles"] as? [String: String] {
            titles = rawTitles
        }

        return CodexGlobalState(
            activeWorkspaceRoots: activeRoots,
            savedWorkspaceRoots: savedRoots,
            agentMode: agentMode,
            threadTitles: titles
        )
    }

    func loadRecentHistory(limit: Int = 200) -> [CodexHistoryEntry] {
        let url = rootURL.appendingPathComponent("history.jsonl", isDirectory: false)
        guard let data = try? Data(contentsOf: url),
              let raw = String(data: data, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        return raw
            .split(whereSeparator: \ .isNewline)
            .suffix(limit)
            .compactMap { line in
                guard let lineData = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(CodexHistoryEntry.self, from: lineData)
            }
    }

    func loadConfig() -> CodexConfig {
        let configURL = rootURL.appendingPathComponent("config.toml", isDirectory: false)
        guard let content = try? String(contentsOf: configURL) else {
            return .empty
        }
        return parseConfig(content: content)
    }

    func parseConfig(content: String) -> CodexConfig {
        var config = CodexConfig.empty
        var currentSection = ""
        var currentProjectPath: String?

        for rawLine in content.split(whereSeparator: \ .isNewline) {
            var line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            if let commentIndex = line.firstIndex(of: "#") {
                line = String(line[..<commentIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                if line.isEmpty { continue }
            }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                currentSection = String(line.dropFirst().dropLast())
                currentProjectPath = nil

                if currentSection.hasPrefix("projects.") {
                    if let firstQuote = currentSection.firstIndex(of: "\""),
                       let lastQuote = currentSection.lastIndex(of: "\""),
                       firstQuote < lastQuote {
                        let path = currentSection[currentSection.index(after: firstQuote)..<lastQuote]
                        currentProjectPath = String(path)
                    }
                }
                continue
            }

            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }

            let key = parts[0]
            let value = parts[1]

            if currentSection.isEmpty {
                if key == "model" {
                    config.model = unquote(value)
                } else if key == "personality" {
                    config.personality = unquote(value)
                }
                continue
            }

            if currentSection.hasPrefix("projects."), key == "trust_level", let currentProjectPath {
                config.projectTrustLevels[currentProjectPath] = unquote(value)
                continue
            }

            if currentSection == "features" {
                let boolVal = parseBool(value)
                config.features[key] = boolVal
            }
        }

        return config
    }

    func buildCodexAgent(global: CodexGlobalState, config: CodexConfig) -> UnifiedAgent {
        UnifiedAgent(
            id: "codex",
            name: "Codex",
            model: config.model ?? "unknown",
            source: .codex,
            currentTask: global.agentMode,
            progress: global.activeWorkspaceRoots.isEmpty ? 0 : 0.5,
            isActive: !global.activeWorkspaceRoots.isEmpty,
            accent: .slateBlue
        )
    }

    private func unquote(_ value: String) -> String {
        value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    private func parseBool(_ value: String) -> Bool {
        switch value.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            return false
        }
    }
}
