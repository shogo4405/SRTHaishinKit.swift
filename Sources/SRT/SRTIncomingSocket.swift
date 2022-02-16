import Foundation

final class SRTIncomingSocket: SRTSocket {
    override func configure(_ binding: SRTSocketOption.Binding, _ sock: SRTSOCKET) -> Bool {
        switch binding {
        case .pre:
            return super.configure(binding, sock)
        case .post:
            options[.rcvsyn] = true
            options[.rcvlatency] = 0
            options[.peerlatency] = 0
            if 0 < timeout {
                options[.rcvtimeo] = timeout
            }
            return super.configure(binding, sock)
        }
    }
}
