import Foundation

///  An object for writing interpolated string messages to srt logging system.
public class SRTLogger {
    public enum Level {
        /// Highly detailed and very frequent messages.
        case debug
        /// Occasionally displayed information.
        case notice
        /// Unusual behavior.
        case warning
        /// Abnormal behavior
        case error
        /// Error that makes the current socket unusabl
        case crit

        var value: Int32 {
            switch self {
            case .debug:
                return LOG_DEBUG
            case .notice:
                return LOG_NOTICE
            case .warning:
                return LOG_WARNING
            case .error:
                return LOG_ERR
            case .crit:
                return LOG_CRIT
            }
        }
    }

    static public let shared = SRTLogger()

    private init() {
        srt_setloglevel(level.value)
    }

    /// Specifies the current logging level.
    public var level: Level = .notice{
        didSet {
            guard level != oldValue else {
                return
            }
            srt_setloglevel(level.value)
        }
    }
}
