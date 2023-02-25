import UIKit
import Logboard
import AVFoundation
import HaishinKit
import SRTHaishinKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LBLogger.with(HaishinKitIdentifier).level = .trace
        SRTLogger.shared.level = .debug
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try session.setPreferredSampleRate(44_100)
            // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
            if #available(iOS 10.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
            } else {
                session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [AVAudioSession.CategoryOptions.allowBluetooth])
                try? session.setMode(.default)
            }
            try session.setActive(true)
        } catch {
        }
        return true
    }
}
