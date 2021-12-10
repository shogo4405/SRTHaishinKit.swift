import Foundation

public enum SRTError: Error {
    case illegalState(message: String)
    case invalidArgument(message: String)
}
