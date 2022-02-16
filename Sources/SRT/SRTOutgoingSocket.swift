import Foundation

final class SRTOutgoingSocket: SRTSocket {
    static let payloadSize: Int = 1316

    private var lostBytes: Int64 = 0
    private var wroteBytes: Int64 = 0
    private var pendingData: [Data] = []
    private let writeQueue: DispatchQueue = DispatchQueue(label: "com.haishinkit.srt.SRTOutgoingSocket.write")

    func write(_ data: Data) {
        writeQueue.async {
            self.pendingData.append(contentsOf: data.chunk(SRTOutgoingSocket.payloadSize))
            repeat {
                if let data = self.pendingData.first {
                    data.withUnsafeBytes { (buffer: UnsafePointer<Int8>) -> Void in
                        srt_sendmsg2(self.socket, buffer, Int32(data.count), nil)
                    }
                    self.pendingData.remove(at: 0)
                }
            } while !self.pendingData.isEmpty
        }
    }

    override func configure(_ binding: SRTSocketOption.Binding, _ sock: SRTSOCKET) -> Bool {
        switch binding {
        case .pre:
            return super.configure(binding, sock)
        case .post:
            options[.sndsyn] = true
            options[.peerlatency] = 0
            if 0 < timeout {
                options[.sndtimeo] = timeout
            }
            return super.configure(binding, sock)
        }
    }
}
