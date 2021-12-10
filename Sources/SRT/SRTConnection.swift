import Foundation

open class SRTConnection: NSObject {
    /// SRT Library version
    static public let version: String = SRT_VERSION_STRING

    /// The URI passed to the SRTConnection.connect() method.
    public private(set) var uri: URL?
    /// This instance connect to server(true) or not(false)
    @objc dynamic public private(set) var connected: Bool = false
    
    /// Track if a connection that was working was closed unexpectedly
    @objc dynamic public private(set) var connectionBroken: Bool = false
    
    /// This instance is running a service listening for client to connect
    @objc dynamic public private(set) var listening: Bool = false
    
    var incomingSocket: SRTIncomingSocket?
    var outgoingSocket: SRTOutgoingSocket?
    private var streams: [SRTStream] = []

    public override init() {
        super.init()
    }

    deinit {
        streams.removeAll()
    }
    
    /**
     Establish a SRT connection to the given host as a caller
     
     - parameters:
        - uri: Encoding of the SRT listener host, port and socket options, must use the srt:// schema
        - withIncomingSocket: Optional parameter to establish a 2 way connection with the host.
            The incomming socket shouldn't be needed, however it can be used to detect problems with OBS's reconnection behaviour.
            Disconnecting and trying to reconnect to OBS immediately doesn't work if you create an incoming socket as well you can detect this failure
            otherwise things will appear to connect and send data, but you won't see the results in OBS
     */
    public func connect(_ uri: URL?, withIncomingSocket: Bool = false) throws {
        guard let uri = uri, let scheme = uri.scheme, let host = uri.host, let port = uri.port, scheme == "srt" else {
            throw SRTError.invalidArgument(message: "Invalid Configuration")
        }
        
        self.uri = uri
        let options = SRTSocketOption.from(uri: uri)
        let addr = sockaddr_in(host, port: UInt16(port))
        
        if(connectionBroken) {
            connectionBroken = false;
        }
        
        outgoingSocket = SRTOutgoingSocket()
        outgoingSocket?.delegate = self
        try outgoingSocket?.connect(addr, options: options)
        
        if(withIncomingSocket)
        {
            incomingSocket = SRTIncomingSocket()
            incomingSocket?.delegate = self
            try incomingSocket?.connect(addr, options: options)
        }
    }
    
    /**
     Establish a SRT connection as the host in listening mode
     
     - parameters:
        - uri: Encoding of the SRT port and socket options, must use the srt:// schema
     */
    public func listen(_ uri: URL?) throws {
        guard let uri = uri, let scheme = uri.scheme, let port = uri.port, scheme == "srt" else { return }
        let host = "0.0.0.0"
        
        self.uri = uri
        let options = SRTSocketOption.from(uri: uri)
        let addr = sockaddr_in(host, port: UInt16(port))
        
        if(connectionBroken) {
            connectionBroken = false;
        }
        
        outgoingSocket = SRTOutgoingSocket()
        outgoingSocket?.delegate = self
        try outgoingSocket?.listen(addr, options: options)
    }

    public func close() {
        for stream in streams {
            stream.close()
        }
        outgoingSocket?.close()
        incomingSocket?.close()
        incomingSocket = nil
    }

    public func attachStream(_ stream: SRTStream) {
        streams.append(stream)
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
    func status(_ socket: SRTSocket, status: SRT_SOCKSTATUS) {
        guard let outgoingSocket = outgoingSocket else {
            return
        }
        connected = outgoingSocket.status == SRTS_CONNECTED
        if(!connectionBroken && outgoingSocket.status == SRTS_BROKEN) {
            connectionBroken = true;
        }
        listening = outgoingSocket.status == SRTS_LISTENING
        
        guard let incomingSocket = incomingSocket else {
            return
        }
        connected = connected && incomingSocket.status == SRTS_CONNECTED
        if(!connectionBroken && incomingSocket.status == SRTS_BROKEN) {
            connectionBroken = true;
        }
    }
}
