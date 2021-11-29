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
    private(set) var bindSocket: SRTSOCKET = SRT_INVALID_SOCK
    
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
        socket = srt_create_socket()
        if socket == SRT_INVALID_SOCK {
            throw createConnectionException()
        }

        self.options = options
        guard configure(.pre, socket) else {
            throw createConnectionException()
        }

        // prepare connect
        var addr_cp = addr
        let stat = withUnsafePointer(to: &addr_cp) { ptr -> Int32 in
            let psa = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return srt_connect(socket, psa, Int32(MemoryLayout.size(ofValue: addr)))
        }

        if stat == SRT_ERROR {
            throw createConnectionException()
        }
        
        guard configure(.post, socket) else {
            throw createConnectionException()
        }

        startRunning()
    }
    
    private func createConnectionException() -> SRTError {
        let error_message = String(cString: srt_getlasterror_str())

        logger.error(error_message)
        return SRTError.illegalState(message: error_message)
    }

    func close() {
        if(socket != SRT_INVALID_SOCK) {
            srt_close(socket)
            socket = SRT_INVALID_SOCK
        }
        if bindSocket != SRT_INVALID_SOCK {
            srt_close(bindSocket)
            bindSocket = SRT_INVALID_SOCK
        }
    }
    
    func configure(_ binding: SRTSocketOption.Binding, _ sock: SRTSOCKET) -> Bool {
        let failures = SRTSocketOption.configure(sock, binding: binding, options: options)
        guard failures.isEmpty else {
            logger.error(failures); return false
        }
        return true
    }
    
    func listen(_ addr: sockaddr_in, options: [SRTSocketOption: Any] = SRTSocket.defaultOptions) throws {
        guard bindSocket == SRT_INVALID_SOCK else { return }
        
        self.options = options
        
        // Create a socket, bind it and start listening for connections
        bindSocket = srt_create_socket()
        if bindSocket == SRT_INVALID_SOCK {
            throw createConnectionException()
        }

        guard configure(.pre, bindSocket) else { return }
        
        var addr_cp = addr
        var stat = withUnsafePointer(to: &addr_cp) { ptr -> Int32 in
            let psa = UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
            return srt_bind(bindSocket, psa, Int32(MemoryLayout.size(ofValue: addr)))
        }
        if stat == SRT_ERROR {
            throw createConnectionException()
        }
        // only supporting a single connection
        stat = srt_listen(bindSocket, 1)
        if stat == SRT_ERROR {
            srt_close(bindSocket)
            throw createConnectionException()
        }
        
        // setup polling of the socket to manage incoming connections
        let eid = srt_epoll_create()
        guard eid >= 0 else {
            srt_close(bindSocket)
            throw createConnectionException()
        }
        var eventMask:Int32 = Int32(SRT_EPOLL_IN.rawValue)
        stat = srt_epoll_add_usock(eid, bindSocket, &eventMask)
        if stat == SRT_ERROR {
            srt_close(bindSocket)
            throw createConnectionException()
        }
        
        // ensure everything is setup correctly and then move listening to another thread
        self.status = srt_getsockstate(bindSocket)
        if(self.status != SRTS_LISTENING) {
            srt_close(bindSocket)
            throw createConnectionException()
        }
        
        DispatchQueue(label:"com.HaishkinKit.SRTSocket.listen").async {
            do {
             try self.waitForConnection(eid)
            } catch {
                logger.error("Issue while processing data on listener socket: ", error)
                self.status = SRTS_BROKEN
            }
        }
    }
    
    private func waitForConnection(_ eid: Int32) throws {
               
        // only deal 1 event
        let events: UnsafeMutablePointer<SRT_EPOLL_EVENT> = UnsafeMutablePointer<SRT_EPOLL_EVENT>.allocate(capacity: 1)
        while true {
            
            if bindSocket == SRT_INVALID_SOCK {
                logger.info("Stopped listening")
                return
            }
            
            // poll for an incoming connection
            let eventCount = srt_epoll_uwait(eid, events, 1, 100)
            if eventCount > 0 {
                let event = events.pointee
                logger.trace("Listening event: ", event)
                try self.completeConnection()
                srt_epoll_remove_usock(eid, event.fd)
                return
            }
        }
    }
    
    private func completeConnection() throws {
        let status = srt_getsockstate(bindSocket)
        
        guard status == SRTS_LISTENING else {
            return
        }
        
        // the caller has connected to our listening socket accept the connection
        socket = srt_accept(bindSocket, nil, nil)
        
        // only working with one connection can stop listening for more now
        srt_close(bindSocket)
        bindSocket = SRT_INVALID_SOCK
        
        if socket == SRT_INVALID_SOCK {
            throw createConnectionException()
        }
        
        guard configure(.post, socket) else {
            throw createConnectionException()
        }
        
        if srt_getsockstate(socket) != SRTS_CONNECTED {
            throw createConnectionException()
        }
        
        startRunning()
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
