// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "HarmonyCore", platforms: [.iOS(.v16), .macOS(.v13)], products: [.library(name: "HarmonyCore", targets: ["HarmonyCore"])], targets: [.target(name: "HarmonyCore"), .testTarget(name: "HarmonyCoreTests", dependencies: ["HarmonyCore"])])
