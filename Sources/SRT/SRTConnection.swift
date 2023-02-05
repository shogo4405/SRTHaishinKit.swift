import Foundation

/// The SRTConnection class create a two-way SRT connection.
public class SRTConnection: NSObject {
    /// SRT Library version
    static public let version: String = SRT_VERSION_STRING

    /// The URI passed to the SRTConnection.connect() method.
    public private(set) var uri: URL?
    /// This instance connect to server(true) or not(false)
    @objc dynamic public private(set) var connected: Bool = false

    var socket: SRTSocket? {
        didSet {
            socket?.delegate = self
        }
    }
    private var streams: [SRTStream] = []

    /// Creates a new SRTConnection.
    public override init() {
        super.init()
    }

    deinit {
        streams.removeAll()
    }

    /// Creates a two-way connection to an application on SRT Server.
    public func connect(_ uri: URL?) {
        guard let uri = uri, let scheme = uri.scheme, let host = uri.host, let port = uri.port, scheme == "srt" else {
            return
        }
        self.uri = uri
        let options = SRTSocketOption.from(uri: uri)
        let addr = sockaddr_in(host, port: UInt16(port))
        ((try? socket?.connect(addr, options: options)) as ()??)
    }

    /// Closes the connection from the server.
    public func close() {
        for stream in streams {
            stream.close()
        }
        socket?.close()
    }

    private func sockaddr_in(_ host: String, port: UInt16) -> sockaddr_in {
        var addr: sockaddr_in = .init()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = CFSwapInt16BigToHost(UInt16(port))
        if inet_pton(AF_INET, host, &addr.sin_addr) == 1 {
            return addr
        }
        guard let hostent = gethostbyname(host), hostent.pointee.h_addrtype == AF_INET else {
            return addr
        }
        addr.sin_addr = UnsafeRawPointer(hostent.pointee.h_addr_list[0]!).assumingMemoryBound(to: in_addr.self).pointee
        return addr
    }
}

extension SRTConnection: SRTSocketDelegate {
    // MARK: SRTSocketDelegate
    func socket(_ socket: SRTSocket, status: SRT_SOCKSTATUS) {
        connected = socket.status == SRTS_CONNECTED
    }

    func socket(_ socket: SRTSocket, incomingDataAvailabled data: Data, bytes: Int32) {
    }
}
