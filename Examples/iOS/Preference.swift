import Foundation

struct Preference {
    static var shared = Preference()

    var url: String = "srt://192.168.1.6:3000"
}
