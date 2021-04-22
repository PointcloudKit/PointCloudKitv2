// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PointCloudProcessorService",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PointCloudProcessorService",
            targets: ["PointCloudProcessorService"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Common", path: "./Common/"),
        .package(name: "PointCloudRendererService", path: "./PointCloudRendererService/"),
        .package(url: "https://github.com/kewlbear/Open3D-iOS.git", .branch("main")),
        .package(url: "https://github.com/kewlbear/PythonKit.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PointCloudProcessorService",
            dependencies: ["Common", "PointCloudRendererService", "Open3D-iOS", "PythonKit"]),
        .testTarget(
            name: "PointCloudProcessorServiceTests",
            dependencies: ["PointCloudProcessorService"])
    ]
)
