import Foundation

actor ClaudeDataService {
    private let fileManager: FileManager
    private let rootURL: URL
    private let parser: JSONLParser
    private let checkpointStore: EventCheckpointStore
    private let taskReducer = TaskEventReducer()
    private let fileReducer = FileActivityReducer()

    private var taskState: [String: UnifiedTask] = [:]
    private var fileState: [String: UnifiedFileActivity] = [:]

    init(
        fileManager: FileManager = .default,
        rootURL: URL? = nil,
        parser: JSONLParser = JSONLParser(),
        checkpointStore: EventCheckpointStore = EventCheckpointStore()
    ) {
        self.fileManager = fileManager
        self.rootURL = rootURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude", isDirectory: true)
        self.parser = parser
        self.checkpointStore = checkpointStore
    }

    func loadTeams() -> [ClaudeTeamConfig] {
        let teamsURL = rootURL.appendingPathComponent("teams", isDirectory: true)
        guard let entries = try? fileManager.contentsOfDirectory(at: teamsURL, includingPropertiesForKeys: nil) else {
            return []
        }

        let decoder = JSONDecoder()
        var result: [ClaudeTeamConfig] = []

        for entry in entries {
            let configURL = entry.appendingPathComponent("config.json", isDirectory: false)
            guard fileManager.fileExists(atPath: configURL.path) else { continue }
            guard let data = try? Data(contentsOf: configURL),
                  let config = try? decoder.decode(ClaudeTeamConfig.self, from: data) else {
                continue
            }
            result.append(config)
        }

        return result
    }

    func loadAllAgents() -> [UnifiedAgent] {
        let teams = loadTeams()
        let colors = AgentAccentColor.allCases
        var idx = 0

        return teams.flatMap { team in
            team.members.map { member in
                defer { idx += 1 }
                return UnifiedAgent(
                    id: member.agentId,
                    name: member.name,
                    model: member.model ?? "unknown",
                    source: .claude,
                    currentTask: nil,
                    progress: 0,
                    isActive: true,
                    accent: colors[idx % colors.count]
                )
            }
        }
    }

    func loadRecentHistory(limit: Int = 200) -> [ClaudeHistoryEntry] {
        let historyURL = rootURL.appendingPathComponent("history.jsonl", isDirectory: false)
        guard fileManager.fileExists(atPath: historyURL.path) else { return [] }

        guard let data = try? Data(contentsOf: historyURL),
              let raw = String(data: data, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        return raw
            .split(whereSeparator: \ .isNewline)
            .suffix(limit)
            .compactMap { line in
                guard let lineData = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(ClaudeHistoryEntry.self, from: lineData)
            }
    }

    func loadStats() -> ClaudeStatsCache? {
        let statsURL = rootURL.appendingPathComponent("stats-cache.json", isDirectory: false)
        guard let data = try? Data(contentsOf: statsURL) else { return nil }
        return try? JSONDecoder().decode(ClaudeStatsCache.self, from: data)
    }

    func ingestProjectEvents(changedPaths: [String]? = nil) async -> ([UnifiedTask], [UnifiedFileActivity]) {
        var candidateFiles: [URL]

        if let changedPaths {
            candidateFiles = changedPaths
                .filter { $0.hasSuffix(".jsonl") }
                .map(URL.init(fileURLWithPath:))
                .filter { $0.path.contains("/.claude/projects/") }
        } else {
            candidateFiles = discoverProjectJSONLFiles()
        }

        var allEvents: [[String: Any]] = []

        for fileURL in candidateFiles {
            let path = fileURL.path
            let offset = await checkpointStore.offset(for: path)

            guard let parsed = try? parser.parseAppendedJSON(from: fileURL, offset: offset) else {
                continue
            }

            allEvents.append(contentsOf: parsed.events)
            await checkpointStore.setOffset(parsed.newOffset, for: path)

            if parsed.wasTruncated {
                await checkpointStore.resetOffset(for: path)
                if let fullParse = try? parser.parseAppendedJSON(from: fileURL, offset: 0) {
                    allEvents.append(contentsOf: fullParse.events)
                    await checkpointStore.setOffset(fullParse.newOffset, for: path)
                }
            }
        }

        taskState = taskReducer.reduce(existing: taskState, events: allEvents)
        fileState = fileReducer.reduce(existing: fileState, events: allEvents)

        let tasks = taskState.values
            .sorted { $0.updatedAt > $1.updatedAt }
        let files = fileState.values
            .sorted { $0.updatedAt > $1.updatedAt }

        return (tasks, files)
    }

    func forceFullRebuildFromProjects() async -> ([UnifiedTask], [UnifiedFileActivity]) {
        await checkpointStore.clearAll()
        taskState.removeAll()
        fileState.removeAll()
        return await ingestProjectEvents(changedPaths: nil)
    }

    private func discoverProjectJSONLFiles() -> [URL] {
        let projectsURL = rootURL.appendingPathComponent("projects", isDirectory: true)
        guard let enumerator = fileManager.enumerator(
            at: projectsURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let url as URL in enumerator where url.pathExtension == "jsonl" {
            urls.append(url)
        }
        return urls
    }
}
