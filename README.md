# [Archived] SRTHaishinKit
[![GitHub license](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://raw.githubusercontent.com/shogo4405/SRTHaishinKit.swift/master/LICENSE.md)
* Camera and Microphone streaming library via SRT for iOS.
* [API Documentation](https://shogo4405.github.io/SRTHaishinKit.swift/)
* This project status is working in progress.

This project has been integrated into [HaishinKit.swift](https://github.com/shogo4405/HaishinKit.swift/)

## 🎨 Features
### SRT
- [x] Publish and Recording (H264/AAC)
- [x] Playback(beta)
- [ ] mode
  - [x] caller
  - [x] listener
  - [ ] rendezvous

## 🌏 Requirements
|-|iOS|Xcode|Swift|
|:-:|:-:|:-:|:-:|
|0.1.0+|11.0+|14.0+|5.7|
|0.0.0+|8.0+|10.0+|4.2|

## 🔧 Installation
Not available.
- CocoaPods

### Carthage
```swift
github "shogo4405/SRTHaishinKit.swift" "0.1.2"
```
### Swift Package Manager
```
https://github.com/shogo4405/SRTHaishinKit.swift
```

## ☕ Cocoa Keys
Please contains Info.plist.

iOS 10.0+
* NSMicrophoneUsageDescription
* NSCameraUsageDescription

## Prerequisites
Make sure you setup and activate your AVAudioSession.
```swift
import AVFoundation
let session: AVAudioSession = AVAudioSession.sharedInstance()
do {
    try session.setPreferredSampleRate(44_100)
    // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
    if #available(iOS 10.0, *) {
        try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
    } else {
        session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with:  [AVAudioSession.CategoryOptions.allowBluetooth])
    }
    try session.setMode(AVAudioSessionModeDefault)
    try session.setActive(true)
} catch {
}
```

## SRT Usage
```swift
let connection = SRTConnection()
let stream = SRTStream(connection: connection)
stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
    // print(error)
}
stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)) { error in
    // print(error)
}

let hkView = HKView(frame: view.bounds)
hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
hkView.attachStream(rtmpStream)

// add ViewController#view
view.addSubview(hkView)

connection.connect("srt://host:port?option=foo")
stream.publish()
```

```swift
let connection = SRTConnection()
let stream = SRTStream(connection: connection)

let hkView = MTHKView(frame: view.bounds)
hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
hkView.attachStream(rtmpStream)

// add ViewController#view
view.addSubview(hkView)

connection.connect("srt://host:port?option=foo")
stream.play("")
```

## 🐾 Examples
SRTHaishinKit needs other dependencies. Please build.

### Prerequisites
```sh
brew install cmake
```

### iOS
```sh
carthage update --use-xcframeworks --platform iOS
```

### You can run the ffplay as SRT service.
```sh
ffplay -analyzeduration 100 -i 'srt://${YOUR_IP_ADDRESS}?mode=listener'
```

## 📖 References
* https://www.haivision.com/products/srt-secure-reliable-transport/

## 📜 License
BSD-3-Clause
