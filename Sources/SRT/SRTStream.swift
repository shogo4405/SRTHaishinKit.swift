import HaishinKit
import Foundation
import AVFoundation

open class SRTStream: NetStream {
    public enum ReadyState: UInt8 {
        case initialized = 0
        case open        = 1
        case play        = 2
        case playing     = 3
        case publish     = 4
        case publishing  = 5
        case closed      = 6
    }

    private var connection: SRTConnection?
    private var name: String?
    private var action: (() -> Void)?
    private var keyValueObservations: [NSKeyValueObservation] = []

    private lazy var tsWriter: TSWriter = {
        var tsWriter = TSWriter()
        tsWriter.delegate = self
        return tsWriter
    }()

    public private(set) var readyState: ReadyState = .initialized {
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
                mixer.startEncoding(delegate: self.tsWriter)
                mixer.startRunning()
                tsWriter.startRunning()
                readyState = .publishing
            default:
                break
            }
        }
    }

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
    open func attachRawMedia(_ type: AVMediaType) {
        tsWriter.expectedMedias.insert(type)
    }

    /**
     Remove a media type that was added via attachRawMedia
     
     - parameters:
        - type: An AVMediaType that was added via an attachRawMedia call
     */
    open func detachRawMedia(_ type: AVMediaType) {
        tsWriter.expectedMedias.remove(type)
    }

    override open func attachCamera(_ camera: AVCaptureDevice?, onError: ((NSError) -> Void)? = nil) {
        if camera == nil {
            tsWriter.expectedMedias.remove(.video)
        } else {
            tsWriter.expectedMedias.insert(.video)
        }
        super.attachCamera(camera, onError: onError)
    }

    override open func attachAudio(_ audio: AVCaptureDevice?, automaticallyConfiguresApplicationAudioSession: Bool = true, onError: ((NSError) -> Void)? = nil) {
        if audio == nil {
            tsWriter.expectedMedias.remove(.audio)
        } else {
            tsWriter.expectedMedias.insert(.audio)
        }
        super.attachAudio(audio, automaticallyConfiguresApplicationAudioSession: automaticallyConfiguresApplicationAudioSession, onError: onError)
    }

    open func publish(_ name: String?) {
        lockQueue.async {
            guard name != nil else {
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

    open func close() {
        if readyState == .closed || readyState == .initialized {
            return
        }
        publish(nil)
        lockQueue.async {
            self.readyState = .closed
        }
    }
}

extension SRTStream: TSWriterDelegate {
    // MARK: TSWriterDelegate
    public func writer(_ writer: TSWriter, didOutput data: Data) {
        guard readyState == .publishing else { return }
        connection?.outgoingSocket?.write(data)
    }
}
