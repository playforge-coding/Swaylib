import CRaylib
import CRaylibShims
import Synchronization

/// raylib's trace log: the messages it prints while loading files, creating the window and so on.
@MainActor
public enum Log {
    /// Receives one log line. Called on whichever thread raylib logs from, usually the main thread.
    public typealias Handler = @Sendable (TraceLogLevel, String) -> Void

    private nonisolated static let handler = Mutex<Handler?>(nil)

    /// Redirects raylib's log to `handler`, or back to stdout when nil.
    ///
    /// Lines arrive whole, however long. A ``TraceLogLevel/fatal`` message still ends the process
    /// once the handler returns, exactly as it does without a handler.
    public static func setHandler(_ handler: Handler?) {
        Self.handler.withLock { $0 = handler }
        swaylibSetLogHandler(handler == nil ? nil : forwardToHandler)
    }

    /// Drops every message below `level`. raylib's default is ``TraceLogLevel/info``.
    public static func setLevel(_ level: TraceLogLevel) {
        SetTraceLogLevel(level.rawValue)
    }

    /// Writes a line to raylib's log, through the handler if one is set.
    ///
    /// Logging at ``TraceLogLevel/fatal`` ends the process with a failure status after the line is
    /// written, whether or not a handler is set, as raylib's own fatal errors do.
    public static func log(_ level: TraceLogLevel, _ message: String) {
        swaylibLog(level.rawValue, message)
    }

    fileprivate nonisolated static func dispatch(_ level: Int32, _ message: String) {
        guard let handler = handler.withLock({ $0 }) else { return }
        handler(TraceLogLevel(rawValue: level) ?? .info, message)
    }
}

private let forwardToHandler: @convention(c) (Int32, UnsafePointer<CChar>?) -> Void = { level, text in
    Log.dispatch(level, text.map { String(cString: $0) } ?? "")
}
