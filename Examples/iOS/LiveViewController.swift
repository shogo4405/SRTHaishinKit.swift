import UIKit
import HaishinKit
import SRTHaishinKit
import AVFoundation

final class LiveViewController: UIViewController {
    private static let maxRetryCount: Int = 5

    @IBOutlet private weak var lfView: MTHKView!
    @IBOutlet private weak var currentFPSLabel: UILabel!
    @IBOutlet private weak var publishButton: UIButton!
    @IBOutlet private weak var pauseButton: UIButton!
    @IBOutlet private weak var videoBitrateLabel: UILabel!
    @IBOutlet private weak var videoBitrateSlider: UISlider!
    @IBOutlet private weak var audioBitrateLabel: UILabel!
    @IBOutlet private weak var zoomSlider: UISlider!
    @IBOutlet private weak var audioBitrateSlider: UISlider!
    @IBOutlet private weak var fpsControl: UISegmentedControl!
    @IBOutlet private weak var effectSegmentControl: UISegmentedControl!

    private var connection: SRTConnection!
    private var stream: SRTStream!
    private var currentPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()
        connection = .init()
        stream = SRTStream(connection)
        stream.sessionPreset = .hd1920x1080
        stream.videoSettings = [
            .width: 720,
            .height: 1280
        ]
        lfView.attachStream(stream)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stream.attachAudio(AVCaptureDevice.default(for: .audio)) { _ in
            // logger.warn(error.description)
        }
        stream.attachCamera(AVCaptureDevice.default(for: .video)) { _ in
            // logger.warn(error.description)
        }
    }

    @IBAction func rotateCamera(_ sender: UIButton) {
    }

    @IBAction func toggleTorch(_ sender: UIButton) {
    }

    @IBAction func on(slider: UISlider) {
    }

    @IBAction func on(pause: UIButton) {
    }

    @IBAction func on(close: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func on(publish: UIButton) {
        if publish.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            stream.close()
            connection.close()
            publish.setTitle("●", for: [])
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            connection.connect(URL(string: Preference.shared.url))
            stream.publish(Preference.shared.streamName)
            publish.setTitle("■", for: [])
        }
        publish.isSelected.toggle()
    }

    func tapScreen(_ gesture: UIGestureRecognizer) {
    }

    @IBAction private func onFPSValueChanged(_ segment: UISegmentedControl) {
    }

    @IBAction private func onEffectValueChanged(_ segment: UISegmentedControl) {
    }

    @objc
    private func on(_ notification: Notification) {
    }

    @objc
    private func didEnterBackground(_ notification: Notification) {
    }

    @objc
    private func didBecomeActive(_ notification: Notification) {
    }
}
