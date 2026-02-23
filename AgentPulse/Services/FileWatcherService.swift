import CoreServices
import Foundation

final class FileWatcherService {
    typealias ChangeHandler = ([String]) -> Void

    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.agentpulse.fsevents", qos: .utility)
    private var onChange: ChangeHandler?

    func start(paths: [String], latency: CFTimeInterval = 1.0, onChange: @escaping ChangeHandler) {
        stop()

        guard !paths.isEmpty else { return }
        self.onChange = onChange

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)

        let createdStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            Self.callback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            flags
        )

        guard let createdStream else { return }
        stream = createdStream

        FSEventStreamSetDispatchQueue(createdStream, queue)
        FSEventStreamStart(createdStream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit {
        stop()
    }

    private static let callback: FSEventStreamCallback = {
        _, info, numEvents, eventPaths, _, _ in
        guard let info else { return }

        let watcher = Unmanaged<FileWatcherService>.fromOpaque(info).takeUnretainedValue()

        let pathsArray: [String]
        if let eventPaths {
            pathsArray = (unsafeBitCast(eventPaths, to: NSArray.self) as? [String]) ?? []
        } else {
            pathsArray = []
        }

        let limitedPaths = Array(pathsArray.prefix(Int(numEvents)))
        watcher.onChange?(limitedPaths)
    }
}
