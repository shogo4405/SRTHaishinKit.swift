// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SRTHaishinKit",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "SRTHaishinKit", targets: ["SRTHaishinKit"])
    ],
    dependencies: [
        .package(
            name: "HaishinKit",
            url: "https://github.com/shogo4405/HaishinKit.swift.git",
            from: "1.3.0"
        )
    ],
    targets: [
        .binaryTarget(
            name: "libsrt",
            path: "Vendor/SRT/libsrt.xcframework"
        ),
        .target(
            name: "SRTHaishinKit",
            dependencies: [
                "libsrt",
                .product(name: "HaishinKit", package: "HaishinKit")
            ],
            path: "Sources",
            sources: [
                "Extension",
                "SRT",
                "Util",
                "Includes"
            ],
            publicHeadersPath: "Includes",
            cSettings: [.headerSearchPath("Includes")]
        )
    ]
)
