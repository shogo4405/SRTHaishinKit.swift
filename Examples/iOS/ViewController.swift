import UIKit
import HaishinKit
import SRTHaishinKit
import AVFoundation

final class ViewController: UIViewController {
    @IBOutlet private weak var hkView: GLHKView?

    private var connection: SRTConnection!
    private var srtStream: SRTStream!

    private var currentPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()

        connection = .init()
        srtStream = SRTStream(connection)
        srtStream.captureSettings = [
            .sessionPreset: AVCaptureSession.Preset.hd1280x720,
            .continuousAutofocus: true,
            .continuousExposure: true
        ]
        srtStream.videoSettings = [
            .width: 720,
            .height: 1280
        ]
        connection?.attachStream(srtStream)
        connection?.connect(URL(string: "srt://192.168.11.15:3000"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        srtStream.attachAudio(AVCaptureDevice.default(for: .audio)) { _ in
            // logger.warn(error.description)
        }
        srtStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { _ in
            // logger.warn(error.description)
        }
        srtStream.publish("hoge")
        hkView?.attachStream(srtStream)
    }
}
