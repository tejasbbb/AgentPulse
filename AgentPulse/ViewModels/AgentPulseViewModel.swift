import Foundation
import SwiftUI

@MainActor
final class AgentPulseViewModel: ObservableObject {
    @Published var agents: [UnifiedAgent] = []
    @Published var tasks: [UnifiedTask] = []
    @Published var fileActivities: [UnifiedFileActivity] = []
    @Published var stats: AggregateStats = .empty
    @Published var pendingApprovals: [ApprovalRequest] = []

    @Published var isFirstLaunch = false
    @Published var showRestartNotice = false
    @Published var installError: String?

    private let claudeService: ClaudeDataService
    private let codexService: CodexDataService
    private let approvalService: ApprovalService
    private let hookInstaller: HookInstaller
    private let watcher = FileWatcherService()

    private var uiRefreshTimer: Timer?
    private var approvalDecisions: [ApprovalDecision] = []

    private enum SnapshotMode: String {
        case live
        case empty
        case active
        case approval
    }

    private let snapshotMode: SnapshotMode

    init(
        claudeService: ClaudeDataService = ClaudeDataService(),
        codexService: CodexDataService = CodexDataService(),
        approvalService: ApprovalService = ApprovalService(),
        hookInstaller: HookInstaller = HookInstaller()
    ) {
        self.claudeService = claudeService
        self.codexService = codexService
        self.approvalService = approvalService
        self.hookInstaller = hookInstaller

        let rawMode = ProcessInfo.processInfo.environment["AGENTPULSE_SNAPSHOT_STATE"] ?? "live"
        self.snapshotMode = SnapshotMode(rawValue: rawMode) ?? .live

        ensureAgentPulseDirectories()
        configureApprovalService()

        if snapshotMode != .live {
            applySnapshotMode(snapshotMode)
            return
        }

        evaluateFirstLaunch()
        startRuntime()
    }

    var pendingApprovalCount: Int {
        pendingApprovals.count
    }

    var taskCompletionFraction: Double {
        guard !tasks.isEmpty else { return 0 }
        let completed = tasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(tasks.count)
    }

    var sortedTasks: [UnifiedTask] {
        tasks.sorted { $0.updatedAt > $1.updatedAt }
    }

    func installHook() {
        do {
            try hookInstaller.installHook()
            isFirstLaunch = false
            showRestartNotice = true
            installError = nil

            let marker = markerURL()
            try Data("installed".utf8).write(to: marker, options: [.atomic])
        } catch {
            installError = error.localizedDescription
        }
    }

    func approve(_ request: ApprovalRequest) {
        approvalService.approve(request)
        approvalDecisions.append(.allow)
        recomputeSuccessRate()
    }

    func deny(_ request: ApprovalRequest) {
        approvalService.deny(request)
        approvalDecisions.append(.deny)
        recomputeSuccessRate()
    }

    func dismissRestartNotice() {
        showRestartNotice = false
    }

    private func startRuntime() {
        approvalService.start()

        Task {
            await fullRefresh()
        }

        startWatcher()

        uiRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    private func configureApprovalService() {
        approvalService.onPendingChange = { [weak self] pending in
            self?.pendingApprovals = pending
        }
    }

    private func startWatcher() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let watchPaths = [
            home.appendingPathComponent(".claude/teams").path,
            home.appendingPathComponent(".claude/projects").path,
            home.appendingPathComponent(".claude/file-history").path,
            home.appendingPathComponent(".codex").path,
            home.appendingPathComponent(".agentpulse/pending").path
        ]

        watcher.start(paths: watchPaths) { [weak self] changedPaths in
            guard let self else { return }
            Task { @MainActor in
                await self.partialRefresh(changedPaths: changedPaths)
            }
        }
    }

    private func fullRefresh() async {
        agents = await claudeService.loadAllAgents()

        let codexGlobal = codexService.loadGlobalState()
        let codexConfig = codexService.loadConfig()
        let codexAgent = codexService.buildCodexAgent(global: codexGlobal, config: codexConfig)
        if codexAgent.isActive {
            agents.append(codexAgent)
        }

        let (newTasks, newFiles) = await claudeService.forceFullRebuildFromProjects()
        tasks = Array(newTasks.prefix(50))
        fileActivities = Array(newFiles.prefix(50))

        let codexHistory = codexService.loadRecentHistory(limit: 500)
        let claudeStats = await claudeService.loadStats()

        stats = computeStats(
            claudeStats: claudeStats,
            codexHistory: codexHistory,
            activeAgents: agents.filter(\ .isActive).count
        )
    }

    private func partialRefresh(changedPaths: [String]) async {
        let hasProjectChange = changedPaths.contains { $0.contains("/.claude/projects/") && $0.hasSuffix(".jsonl") }
        let hasTeamsChange = changedPaths.contains { $0.contains("/.claude/teams/") }
        let hasCodexChange = changedPaths.contains { $0.contains("/.codex/") }

        if hasProjectChange {
            let (newTasks, newFiles) = await claudeService.ingestProjectEvents(changedPaths: changedPaths)
            tasks = Array(newTasks.prefix(50))
            fileActivities = Array(newFiles.prefix(50))
        }

        if hasTeamsChange {
            var combined = await claudeService.loadAllAgents()
            let codexGlobal = codexService.loadGlobalState()
            let codexConfig = codexService.loadConfig()
            let codexAgent = codexService.buildCodexAgent(global: codexGlobal, config: codexConfig)
            if codexAgent.isActive {
                combined.append(codexAgent)
            }
            agents = combined
        }

        if hasCodexChange {
            var combined = await claudeService.loadAllAgents()
            let codexGlobal = codexService.loadGlobalState()
            let codexConfig = codexService.loadConfig()
            let codexAgent = codexService.buildCodexAgent(global: codexGlobal, config: codexConfig)
            if codexAgent.isActive {
                combined.append(codexAgent)
            }
            agents = combined
        }

        recomputeSuccessRate()
    }

    private func computeStats(
        claudeStats: ClaudeStatsCache?,
        codexHistory: [CodexHistoryEntry],
        activeAgents: Int
    ) -> AggregateStats {
        let today = Date()
        let calendar = Calendar.current

        let todayMessages = claudeStats?
            .dailyActivity?
            .first(where: { entry in
                guard let date = ISO8601DateFormatter.shortDate.date(from: entry.date) else { return false }
                return calendar.isDate(date, inSameDayAs: today)
            })?
            .messageCount ?? 0

        let todayToolCalls = claudeStats?
            .dailyActivity?
            .first(where: { entry in
                guard let date = ISO8601DateFormatter.shortDate.date(from: entry.date) else { return false }
                return calendar.isDate(date, inSameDayAs: today)
            })?
            .toolCallCount ?? 0

        let codexTodayMessages = codexHistory.filter {
            calendar.isDate(Date(timeIntervalSince1970: TimeInterval($0.ts)), inSameDayAs: today)
        }.count

        var result = AggregateStats(
            activeAgents: activeAgents,
            totalMessages: todayMessages + codexTodayMessages,
            totalToolCalls: todayToolCalls,
            successRate: stats.successRate
        )

        let denominator = approvalDecisions.count
        if denominator > 0 {
            let allows = approvalDecisions.filter { $0 == .allow }.count
            result.successRate = Double(allows) / Double(denominator)
        }

        return result
    }

    private func recomputeSuccessRate() {
        if approvalDecisions.isEmpty {
            stats.successRate = 0
            return
        }

        let allows = approvalDecisions.filter { $0 == .allow }.count
        stats.successRate = Double(allows) / Double(approvalDecisions.count)
    }

    private func evaluateFirstLaunch() {
        let marker = markerURL()
        isFirstLaunch = !FileManager.default.fileExists(atPath: marker.path)
    }

    private func ensureAgentPulseDirectories() {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agentpulse", isDirectory: true)
        let dirs = ["pending", "responses", "hooks", "state"]
        for dir in dirs {
            try? FileManager.default.createDirectory(
                at: base.appendingPathComponent(dir, isDirectory: true),
                withIntermediateDirectories: true
            )
        }
    }

    private func markerURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agentpulse", isDirectory: true)
            .appendingPathComponent(".installed", isDirectory: false)
    }

    private func applySnapshotMode(_ mode: SnapshotMode) {
        switch mode {
        case .empty:
            agents = []
            tasks = []
            fileActivities = []
            pendingApprovals = []
            stats = AggregateStats(activeAgents: 0, totalMessages: 0, totalToolCalls: 0, successRate: 0)

        case .active:
            seedActiveSnapshot(approval: false)

        case .approval:
            seedActiveSnapshot(approval: true)

        case .live:
            break
        }
    }

    private func seedActiveSnapshot(approval: Bool) {
        agents = [
            UnifiedAgent(id: "a1", name: "team-lead", model: "claude-opus-4-6", source: .claude, currentTask: "Plan architecture", progress: 0.8, isActive: true, accent: .amber),
            UnifiedAgent(id: "a2", name: "researcher", model: "claude-opus-4-6", source: .claude, currentTask: "Analyze hooks", progress: 0.55, isActive: true, accent: .mint),
            UnifiedAgent(id: "a3", name: "implementer", model: "claude-sonnet-4-5", source: .claude, currentTask: "Build UI", progress: 0.35, isActive: true, accent: .coral),
            UnifiedAgent(id: "codex", name: "Codex", model: "gpt-5.3-codex", source: .codex, currentTask: "Refactor parser", progress: 0.62, isActive: true, accent: .slateBlue)
        ]

        tasks = [
            UnifiedTask(id: "t1", subject: "Implement JWT middleware", status: .inProgress, owner: "researcher", updatedAt: Date().addingTimeInterval(-25)),
            UnifiedTask(id: "t2", subject: "Build approval bridge", status: .inProgress, owner: "team-lead", updatedAt: Date().addingTimeInterval(-60)),
            UnifiedTask(id: "t3", subject: "Create stats section", status: .pending, owner: "implementer", updatedAt: Date().addingTimeInterval(-120)),
            UnifiedTask(id: "t4", subject: "Set up models", status: .completed, owner: "team-lead", updatedAt: Date().addingTimeInterval(-300))
        ]

        fileActivities = [
            UnifiedFileActivity(id: "f1", path: "src/middleware/auth.ts", source: .claude, updatedAt: Date().addingTimeInterval(-12)),
            UnifiedFileActivity(id: "f2", path: "src/views/MenuBarDropdownView.swift", source: .claude, updatedAt: Date().addingTimeInterval(-80)),
            UnifiedFileActivity(id: "f3", path: "README.md", source: .codex, updatedAt: Date().addingTimeInterval(-360))
        ]

        if approval {
            pendingApprovals = [
                ApprovalRequest(
                    id: "req-1",
                    createdAt: Date().addingTimeInterval(-18),
                    source: "claude",
                    sessionId: "s1",
                    toolUseId: "u1",
                    toolName: "Bash",
                    toolInput: ["command": AnyCodable("npm test")],
                    riskLevel: .high,
                    riskReason: "Policy ask for Bash (risk: high)",
                    timeoutSeconds: 115
                )
            ]
        }

        stats = AggregateStats(activeAgents: agents.count, totalMessages: 47, totalToolCalls: 132, successRate: 0.86)
    }
}

private extension ISO8601DateFormatter {
    static let shortDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
