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
                .profileLevel: kVTProfileLevel_H264_High_AutoLevel
            ]
        }
       
        
   
        
       //connection!.connect(URL(string: "srt://134.209.120.63:10080?streamid=#!::h=live/livestream,m=publish"))
   
    
         //   self.srtStream.videoSettings[.bitrate] = 1 * 1000000 // video output bitrate
      
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
    
    
    @IBOutlet weak var streamToggle: UIButton!
    //handle situations
    @IBAction func streamToggleBTN(_ sender: Any) {
        streamToggle.setTitle( !connection.connected ? "Stop Broadcast" : "Start Broadcast", for: .normal)
        
        if (!connection.connected){
            
        srtStream.publish("hoge")
        connection!.attachStream(srtStream)
            
            //update URL to your SRT Server
         connection!.connect(URL(string: "srt://srt1.development.seasoncast.com:8080?streamid=uplive.sls.com/live/test"))
            
        }else{
            srtStream.close()
            connection.close()
        }
        
        
    }
    
    
}
