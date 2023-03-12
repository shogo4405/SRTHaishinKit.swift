import UIKit
import HaishinKit
import SRTHaishinKit
import AVFoundation

final class PlaybackViewController: UIViewController {
    private static let maxRetryCount: Int = 5

    @IBOutlet private weak var hkView: PiPHKView!
    private var connection: SRTConnection!
    private var stream: SRTStream!
    private var currentPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()
        connection = .init()
        stream = SRTStream(connection)
        hkView.attachStream(stream)
    }

    @IBAction func on(playback: UIButton) {
        if playback.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            stream.close()
            connection.close()
            playback.setTitle("●", for: [])
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            connection.connect(URL(string: Preference.shared.url))
            stream.play("")
            playback.setTitle("■", for: [])
        }
        playback.isSelected.toggle()
    }
}
