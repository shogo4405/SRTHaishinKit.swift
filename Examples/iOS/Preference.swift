import Foundation

struct Preference {
    static var shared = Preference()

    var url: String = "srt://192.168.1.9:3000"
    var streamName: String = "hoge"
}
