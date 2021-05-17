import Foundation
import HaishinKit
import Logboard

protocol SRTSocketDelegate: AnyObject {
    func status(_ socket: SRTSocket, status: SRT_SOCKSTATUS)
}

class SRTSocket {
    static let defaultOptions: [SRTSocketOption: Any] = [:]

    var timeout: Int = 0
    var options: [SRTSocketOption: Any] = [:] {
        didSet {
            options[.rcvsyn] = true
            options[.tsbdmode] = true
        }
    }
    weak var delegate: SRTSocketDelegate?
    private(set) var isRunning: Atomic<Bool> = .init(false)

    private let lockQueue: DispatchQueue = DispatchQueue(label: "com.haishinkit.SRTHaishinKit.SRTSocket.lock")
    private(set) var socket: SRTSOCKET = SRT_INVALID_SOCK
    private(set) var status: SRT_SOCKSTATUS = SRTS_INIT {
        didSet {
            guard status != oldValue else { return }
            delegate?.status(self, status: status)
            switch status {
            case SRTS_INIT: // 1
                logger.trace("SRT Socket Init")
                break
            case SRTS_OPENED:
                logger.info("SRT Socket opened")
                break
            case SRTS_LISTENING:
                logger.trace("SRT Socket Listening")
                break
            case SRTS_CONNECTING:
                logger.trace("SRT Socket Connecting")
                break
            case SRTS_CONNECTED:
                logger.info("SRT Socket Connected")
                break
            case SRTS_BROKEN:
                logger.warn("SRT Socket Broken")
                close()
            case SRTS_CLOSING:
                logger.trace("SRT Socket Closing")
                break
            case SRTS_CLOSED:
                logger.info("SRT Socket Closed")
                stopRunning()
            case SRTS_NONEXIST:
                logger.warn("SRT Socket Not Exist")
                break
            default:
                break
            }
        }
    }

    func connect(_ addr: sockaddr_in, options: [SRTSocketOption: Any] = SRTSocket.defaultOptions) throws {

        guard socket == SRT_INVALID_SOCK else {
            return
        }

        // prepare socket
        socket = srt_socket(AF_INET, SOCK_DGRAM, 0)
        if socket == SRT_ERROR {
                let error_message = String(cString: srt_getlasterror_str())

                logger.error(error_message)
                throw SRTError.illegalState(message: error_message)
        }

        self.options = options
        guard configure(.pre) else {
            return
        }

        // prepare connect
        var addr_cp = addr
        let stat = withUnsafePointer(to: &addr_cp) { ptr -> Int32 in
            let psa = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return srt_connect(socket, psa, Int32(MemoryLayout.size(ofValue: addr)))
        }

        if stat == SRT_ERROR {

            let error_message = String(cString: srt_getlasterror_str())

            logger.error(error_message)
            throw SRTError.illegalState(message: error_message)
        }

        guard configure(.post) else {
            return
        }

        startRunning()
    }

    func close() {
        guard socket != SRT_INVALID_SOCK else { return }
        srt_close(socket)
        socket = SRT_INVALID_SOCK
    }

    func configure(_ binding: SRTSocketOption.Binding) -> Bool {
        let failures = SRTSocketOption.configure(socket, binding: binding, options: options)
        guard failures.isEmpty else {
            logger.error(failures); return false
        }
        return true
    }
}

extension SRTSocket: Running {
    // MARK: Running
    func startRunning() {
        lockQueue.async {
            self.isRunning.mutate { $0 = true }
            repeat {
                self.status = srt_getsockstate(self.socket)
                usleep(3 * 10000)
            } while self.isRunning.value
        }
    }

    func stopRunning() {
        isRunning.mutate { $0 = false }
    }
}
