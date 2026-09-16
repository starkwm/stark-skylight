// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "StarkSkyLight",
  platforms: [.macOS(.v26)],
  products: [.library(name: "StarkSkyLight", targets: ["StarkSkyLight"])],
  targets: [
    .target(name: "StarkSkyLight"),
    .testTarget(name: "StarkSkyLightTests", dependencies: ["StarkSkyLight"]),
  ]
)
