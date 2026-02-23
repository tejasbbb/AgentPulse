import Foundation

actor EventCheckpointStore {
    private struct CheckpointRecord: Codable {
        var offset: UInt64
        var updatedAt: Date
    }

    private let checkpointURL: URL
    private var records: [String: CheckpointRecord] = [:]
    private var didLoad = false

    init(fileManager: FileManager = .default, checkpointURL: URL? = nil) {
        self.checkpointURL = checkpointURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".agentpulse", isDirectory: true)
            .appendingPathComponent("state", isDirectory: true)
            .appendingPathComponent("checkpoints.json", isDirectory: false)
    }

    func offset(for path: String) async -> UInt64 {
        await ensureLoaded()
        return records[path]?.offset ?? 0
    }

    func setOffset(_ offset: UInt64, for path: String) async {
        await ensureLoaded()
        records[path] = CheckpointRecord(offset: offset, updatedAt: Date())
        await persist()
    }

    func resetOffset(for path: String) async {
        await ensureLoaded()
        records[path] = CheckpointRecord(offset: 0, updatedAt: Date())
        await persist()
    }

    func clearAll() async {
        await ensureLoaded()
        records.removeAll()
        await persist()
    }

    private func ensureLoaded() async {
        guard !didLoad else { return }
        didLoad = true

        guard let data = try? Data(contentsOf: checkpointURL) else {
            records = [:]
            return
        }

        records = (try? JSONDecoder().decode([String: CheckpointRecord].self, from: data)) ?? [:]
    }

    private func persist() async {
        do {
            try FileManager.default.createDirectory(
                at: checkpointURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: checkpointURL, options: [.atomic])
        } catch {
            // Best-effort persistence; parser can still operate with in-memory state.
        }
    }
}
