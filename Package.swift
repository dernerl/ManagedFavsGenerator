// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ManagedFavsGenerator",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "ManagedFavsGenerator", targets: ["ManagedFavsGenerator"])
    ],
    targets: [
        .executableTarget(
            name: "ManagedFavsGenerator",
            resources: [.process("Resources")]
        )
    ]
)
