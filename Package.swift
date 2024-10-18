// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var sokolTarget = Target.target(
  name: "SokolC",
  // exclude: ["sokol/tests"],
  sources: ["sokol_impl.c"],
  // publicHeadersPath: "sokol/",
  cSettings: [.define("SOKOL_IMPL"),
              .define("SOKOL_METAL", .when(platforms: [.macOS])),
              .define("SOKOL_NO_ENTRY"),
              .unsafeFlags(["-x", "objective-c"], .when(platforms: [.macOS]))])

// var glfwTarget = Target.target(
//   name: "Glfw",
//   cSettings: [
//     .unsafeFlags(["-I/usr/local/include"], .when(platforms: [.macOS]))
//   ],
//   linkerSettings: [
//         .unsafeFlags(["-L/usr/local/lib"], .when(platforms: [.macOS]))
//       ]
// )

var glfwTarget = Target.systemLibrary(
  name: "Glfw",
  pkgConfig: "glfw3",
  providers: [
    .brew(["glfw"])]
)

let package = Package(
  name: "Z4",
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    glfwTarget,
    sokolTarget,
    .executableTarget(
      name: "Z4",
      dependencies: ["Glfw", "SokolC"],
      swiftSettings: [
        .unsafeFlags(["-I/usr/local/include"], .when(platforms: [.macOS]))
      ],
      linkerSettings: [
        .unsafeFlags(["-L/usr/local/lib"], .when(platforms: [.macOS]))
      ]
    )
  ]
)
