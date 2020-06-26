import UIKit
import HaishinKit
import SRTHaishinKit
import AVFoundation
import VideoToolbox
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
            .sessionPreset: AVCaptureSession.Preset.hd1920x1080,
            .continuousAutofocus: true,
            .continuousExposure: true,
            .fps: 30
        ]
       
        if #available(iOS 11.0, *) {
            srtStream.videoSettings = [
                .width: 1080,
                .height: 1920,
                .bitrate: 2 * 1000000, // video output bitrate
                .profileLevel: kVTProfileLevel_HEVC_Main_AutoLevel
            ]
        } else {
            // Fallback on earlier versions
        }
       
        
         srtStream.publish("hoge")
        connection!.attachStream(srtStream)
        
       //connection!.connect(URL(string: "srt://134.209.120.63:10080?streamid=#!::h=live/livestream,m=publish"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.connection!.connect(URL(string: "srt://192.168.0.250:8080?streamid=uplive.sls.com/live/test"))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.srtStream.videoSettings[.bitrate] = 1 * 1000000 // video output bitrate
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        srtStream.attachAudio(AVCaptureDevice.default(for: .audio)) { _ in
            // logger.warn(error.description)
        }
        srtStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { _ in
            // logger.warn(error.description)
        }
        
        hkView?.attachStream(srtStream)
    }
}
