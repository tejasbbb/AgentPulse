import Foundation

struct FileActivityReducer {
    func reduce(
        existing: [String: UnifiedFileActivity],
        events: [[String: Any]]
    ) -> [String: UnifiedFileActivity] {
        var state = existing

        for event in events {
            guard (event["type"] as? String) == "file-history-snapshot" else {
                continue
            }

            guard let snapshot = event["snapshot"] as? [String: Any] else {
                continue
            }

            let snapshotDate = parseDate(snapshot["timestamp"] as? String)
            guard let tracked = snapshot["trackedFileBackups"] as? [String: Any] else {
                continue
            }

            for (path, metadataAny) in tracked {
                let metadata = metadataAny as? [String: Any]
                let backupTime = parseDate(metadata?["backupTime"] as? String) ?? snapshotDate

                if let existingItem = state[path], existingItem.updatedAt >= backupTime {
                    continue
                }

                state[path] = UnifiedFileActivity(
                    id: path,
                    path: path,
                    source: .claude,
                    updatedAt: backupTime
                )
            }
        }

        return state
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) {
            return date
        }

        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }
}
