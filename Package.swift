// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MemoryPulse",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MemoryPulse",
            targets: ["MemoryPulse"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MemoryPulse",
            path: "Sources/MemoryPulse",
            exclude: ["Resources"]
        )
    ]
)
