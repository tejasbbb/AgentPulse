import Foundation

@MainActor
final class ApprovalService {
    private let fileManager: FileManager
    private let pendingDir: URL
    private let responsesDir: URL

    private var timer: Timer?
    private(set) var pendingRequests: [ApprovalRequest] = []
    var onPendingChange: (([ApprovalRequest]) -> Void)?

    init(fileManager: FileManager = .default, rootURL: URL? = nil) {
        self.fileManager = fileManager
        let base = rootURL
            ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".agentpulse", isDirectory: true)
        self.pendingDir = base.appendingPathComponent("pending", isDirectory: true)
        self.responsesDir = base.appendingPathComponent("responses", isDirectory: true)
    }

    func start() {
        stop()
        refreshPending()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPending()
                self?.cleanupStalePending()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refreshPending() {
        guard let files = try? fileManager.contentsOfDirectory(at: pendingDir, includingPropertiesForKeys: nil) else {
            pendingRequests = []
            onPendingChange?([])
            return
        }

        var parsed: [ApprovalRequest] = []
        let decoder = Self.makeDecoder()

        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let item = try? decoder.decode(ApprovalRequest.self, from: data) else {
                continue
            }
            parsed.append(item)
        }

        parsed.sort { $0.createdAt > $1.createdAt }
        pendingRequests = parsed
        onPendingChange?(parsed)
    }

    func approve(_ request: ApprovalRequest) {
        let response = ApprovalResponse.allow(id: request.id)
        write(response: response)
    }

    func deny(_ request: ApprovalRequest, reason: String = "Denied via AgentPulse") {
        let response = ApprovalResponse.deny(id: request.id, reason: reason)
        write(response: response)
    }

    private func write(response: ApprovalResponse) {
        do {
            try fileManager.createDirectory(at: responsesDir, withIntermediateDirectories: true)
            let data = try Self.makeEncoder().encode(response)
            let url = responsesDir.appendingPathComponent("\(response.id).json", isDirectory: false)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Keep non-fatal to avoid UI crashes.
        }
    }

    private func cleanupStalePending() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: pendingDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let expiry = Date().addingTimeInterval(-120)
        for fileURL in files where fileURL.pathExtension == "json" {
            guard let values = try? fileURL.resourceValues(forKeys: [.creationDateKey]),
                  let creationDate = values.creationDate else {
                continue
            }

            if creationDate < expiry {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = parseISODate(raw, allowFractional: true) {
                return date
            }
            if let date = parseISODate(raw, allowFractional: false) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO date: \(raw)"
            )
        }
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    nonisolated private static func parseISODate(_ value: String, allowFractional: Bool) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = allowFractional
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
