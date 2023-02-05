import HaishinKit
import Foundation
import AVFoundation

/// An object that provides the interface to control a one-way channel over a SRTConnection.
public class SRTStream: NetStream {
    private enum ReadyState: UInt8 {
        case initialized = 0
        case open        = 1
        case play        = 2
        case playing     = 3
        case publish     = 4
        case publishing  = 5
        case closed      = 6
    }

    private var name: String?
    private var action: (() -> Void)?
    private var keyValueObservations: [NSKeyValueObservation] = []
    private weak var connection: SRTConnection?

    private lazy var tsWriter: TSWriter = {
        var tsWriter = TSWriter()
        tsWriter.delegate = self
        return tsWriter
    }()

    private var readyState: ReadyState = .initialized {
        didSet {
            guard oldValue != readyState else { return }
            switch oldValue {
            case .publishing:
                tsWriter.stopRunning()
                mixer.stopEncoding()
            default:
                break
            }
            switch readyState {
            case .publish:
                mixer.startEncoding(tsWriter)
                mixer.startRunning()
                tsWriter.startRunning()
                readyState = .publishing
            default:
                break
            }
        }
    }

    /// Creates a new SRTStream object.
    public init(_ connection: SRTConnection) {
        super.init()
        self.connection = connection
        let keyValueObservation = connection.observe(\.connected, options: [.new, .old]) { [weak self] _, _ in
            guard let self = self else { return }
            if connection.connected {
                self.action?()
                self.action = nil
            } else {
                self.readyState = .open
            }
        }
        keyValueObservations.append(keyValueObservation)
    }

    deinit {
        connection = nil
        keyValueObservations.removeAll()
    }

    /**
     Prepare the stream to process media of the given type

     - parameters:
     - type: An AVMediaType you will be sending via an appendSampleBuffer call

     As with appendSampleBuffer only video and audio types are supported
     */
    public func attachRawMedia(_ type: AVMediaType) {
        tsWriter.expectedMedias.insert(type)
    }

    /**
     Remove a media type that was added via attachRawMedia

     - parameters:
     - type: An AVMediaType that was added via an attachRawMedia call
     */
    public func detachRawMedia(_ type: AVMediaType) {
        tsWriter.expectedMedias.remove(type)
    }

    override public func attachCamera(_ camera: AVCaptureDevice?, onError: ((Error) -> Void)? = nil) {
        if camera == nil {
            tsWriter.expectedMedias.remove(.video)
        } else {
            tsWriter.expectedMedias.insert(.video)
        }
        super.attachCamera(camera, onError: onError)
    }

    override public func attachAudio(_ audio: AVCaptureDevice?, automaticallyConfiguresApplicationAudioSession: Bool = true, onError: ((Error) -> Void)? = nil) {
        if audio == nil {
            tsWriter.expectedMedias.remove(.audio)
        } else {
            tsWriter.expectedMedias.insert(.audio)
        }
        super.attachAudio(audio, automaticallyConfiguresApplicationAudioSession: automaticallyConfiguresApplicationAudioSession, onError: onError)
    }

    public func publish(_ name: String? = "") {
        lockQueue.async {
            guard let name else {
                switch self.readyState {
                case .publish, .publishing:
                    self.readyState = .open
                default:
                    break
                }
                return
            }
            if self.connection?.connected == true {
                self.readyState = .publish
            } else {
                self.action = { [weak self] in self?.publish(name) }
            }
        }
    }

    public func close() {
        lockQueue.async {
            if self.readyState == .closed || self.readyState == .initialized {
                return
            }
            self.readyState = .closed
        }
    }
}

extension SRTStream: TSWriterDelegate {
    // MARK: TSWriterDelegate
    public func writer(_ writer: TSWriter, didOutput data: Data) {
        guard readyState == .publishing else {
            return
        }
        connection?.socket?.doOutput(data: data)
    }
}
