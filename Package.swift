// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "TaskBoardiOSCore",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(name: "TaskBoardCore", targets: ["TaskBoardCore"]),
    .executable(name: "TaskBoardCoreSmokeTests", targets: ["TaskBoardCoreSmokeTests"]),
  ],
  targets: [
    .target(name: "TaskBoardCore", path: "TaskBoardCore"),
    .executableTarget(
      name: "TaskBoardCoreSmokeTests",
      dependencies: ["TaskBoardCore"],
      path: "TaskBoardCoreSmokeTests"
    ),
    .testTarget(
      name: "TaskBoardCoreTests",
      dependencies: ["TaskBoardCore"],
      path: "TaskBoardCoreTests"
    ),
  ]
)
