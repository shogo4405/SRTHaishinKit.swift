import Foundation
import HaishinKit

protocol SRTSocketDelegate: class {
    func status(_ socket: SRTSocket, status: SRT_SOCKSTATUS)
}

class SRTSocket {
    static let defaultOptions: [SRTSocketOption: Any] = [:]

    weak var delegate: SRTSocketDelegate?
    var timeout: Int = 0
    var options: [SRTSocketOption: Any] = [:] {
        didSet {
            options[.rcvsyn] = true
            options[.tsbdmode] = true
        }
    }
    private(set) var isRunning: Bool = false

    private let lockQueue: DispatchQueue = DispatchQueue(label: "com.haishinkit.SRTHaishinKit.SRTSocket.lock")
    private(set) var socket: SRTSOCKET = SRT_INVALID_SOCK
    private(set) var status: SRT_SOCKSTATUS = SRTS_INIT {
        didSet {
            guard status != oldValue else { return }
            delegate?.status(self, status: status)
            switch status {
            case SRTS_INIT: // 1
                break
            case SRTS_OPENED:
                break
            case SRTS_LISTENING:
                break
            case SRTS_CONNECTING:
                break
            case SRTS_CONNECTED:
                break
            case SRTS_BROKEN:
                close()
            case SRTS_CLOSING:
                break
            case SRTS_CLOSED:
                stopRunning()
            case SRTS_NONEXIST:
                break
            default:
                break
            }
        }
    }

    func connect(_ addr: sockaddr_in, options: [SRTSocketOption: Any] = SRTSocket.defaultOptions) throws {
        guard socket == SRT_INVALID_SOCK else { return }
        // prepare socket
        socket = srt_socket(AF_INET, SOCK_DGRAM, 0)
        if socket == SRT_ERROR {
            throw SRTError.illegalState(message: "")
        }
        self.options = options
        guard configure(.pre) else { return }
        // prepare connect
        var addr_cp = addr
        let stat = withUnsafePointer(to: &addr_cp) { ptr -> Int32 in
            let psa = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return srt_connect(socket, psa, Int32(MemoryLayout.size(ofValue: addr)))
        }
        if stat == SRT_ERROR {
            throw SRTError.illegalState(message: "")
        }
        guard configure(.post) else { return }
        startRunning()
    }

    func close() {
        guard socket != SRT_INVALID_SOCK else { return }
        srt_close(socket)
        socket = SRT_INVALID_SOCK
    }

    func configure(_ binding: SRTSocketOption.Binding) -> Bool {
        let failures = SRTSocketOption.configure(socket, binding: binding, options: options)
        guard failures.isEmpty else { logger.error(failures); return false }
        return true
    }
}

extension SRTSocket: Running {
    // MARK: Running
    func startRunning() {
        lockQueue.async {
            self.isRunning = true
            repeat {
                self.status = srt_getsockstate(self.socket)
                usleep(3 * 10000)
            } while self.isRunning
        }
    }

    func stopRunning() {
        isRunning = false
    }
}
