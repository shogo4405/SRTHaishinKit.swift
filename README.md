# SRTHaishinKit
[![GitHub license](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://raw.githubusercontent.com/shogo4405/SRTHaishinKit.swift/master/LICENSE.md)
* Camera and Microphone streaming library via SRT for iOS.
* This project status is working in progress.

## 🎨 Features
### SRT
- [x] Publish and Recording (H264/AAC)
- [ ] Playback
- [ ] mode
  - [x] caller
  - [ ] listener
  - [ ] rendezvous

### Rendering
|-|HKView|GLHKView|MTHKView|
|-|:---:|:---:|:---:|
|Engine|AVCaptureVideoPreviewLayer|OpenGL ES|Metal|
|Publish|○|○|◯|
|VIsualEffect|×|○|◯|
|Condition|Stable|Stable|Beta|

## 🌏 Requirements
|-|iOS|OSX|tvOS|XCode|Swift|CocoaPods|Carthage|
|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
|0.0.0+|8.0+|10.11+|-|10.0+|4.2|1.5.0+|0.29.0+|

## 🔧 Installation
Not available.
- CocoaPods
- Swift Package Manager

### Carthage
```swift
github "shogo4405/SRTHaishinKit.swift" "main"
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
let srtConnection: SRTConnection = SRTConnection()
let srtStream: SRTStream = SRTStream(connection: srtConnection)
srtStream.attachCamera(DeviceUtil.device(withPosition: .back))
srtStream.attachAudio(AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio))
srtStream.publish("hello")
srtConnection.connect("srt://host:port?option=foo")

var hkView: HKView = HKView(frame: view.bounds)
hkView.attachStream(srtStream)

// add ViewController#view
view.addSubview(hkView)
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
