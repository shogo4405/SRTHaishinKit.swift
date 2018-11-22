# SRTHaishinKit
[![GitHub license](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://raw.githubusercontent.com/shogo4405/SRTHaishinKit.swift/master/LICENSE.md)

* Camera and Microphone streaming library via SRT for iOS.
* Issuesの言語は、英語か、日本語でお願いします！

## Features
### SRT
- [x] Publish and Recording (H264/AAC)
- [ ] Playback
- [ ] mode
  - [x] caller
  - [ ] listener
  - [ ] rendezvous

see also https://github.com/shogo4405/HaishinKit.swift/blob/master/README.md

### Rendering
|-|HKView|GLHKView|MTHKView|
|-|:---:|:---:|:---:|
|Engine|AVCaptureVideoPreviewLayer|OpenGL ES|Metal|
|Publish|○|○|◯|
|VIsualEffect|×|○|◯|
|Condition|Stable|Stable|Beta|

## Requirements
|-|iOS|OSX|tvOS|XCode|Swift|CocoaPods|Carthage|
|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
|0.0.0+|8.0+|10.11+|-|10.0+|4.2|1.5.0+|0.29.0+|

## Cocoa Keys
Please contains Info.plist.

iOS 10.0+
* NSMicrophoneUsageDescription
* NSCameraUsageDescription

## License
BSD-3-Clause

## Donation
Paypal
- https://www.paypal.me/shogo4405

Bitcoin
```txt
1LP7Jo4VwAFdEisJSykBAtUyAusZjozSpw
```

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

## :blue_book: FAQ
### :memo: How can I test SRT Service.
You can run the ffplay as SRT service.
```sh
ffplay -analyzeduration 100 -i 'srt://${YOUR_IP_ADDRESS}?mode=listener'
```

### :memo: How can I run example project?
SRTHaishinKit needs other dependicies. Please build.

#### iOS
```sh
carthage update --platform iOS
cd /Vendor/SRT/
./build-openssl-iOS.sh
./build-srt-iOS.sh
```

#### macOS
```sh
carthage update --platform macOS
brew update
brew install srt
```

### :memo: Do you support me via Email?
Yes. Consulting fee is [$50](https://www.paypal.me/shogo4405/50USD)/1 incident. I don't recommend. 
Please consider to use Issues.

## Dependicies
1. https://github.com/Haivision/srt
1. https://github.com/shogo4405/HaishinKit.swift
1. https://github.com/shogo4405/Logboard

## Refernces
* https://www.haivision.com/products/srt-secure-reliable-transport/
