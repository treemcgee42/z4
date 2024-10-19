// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var sokolTarget = Target.target(
  name: "SokolC",
  sources: ["sokol_impl.mm"],
  cxxSettings: [.define("SOKOL_METAL", .when(platforms: [.macOS])),
                .define("SOKOL_NO_ENTRY"),
                .unsafeFlags([ "-std=c++17"])]
)
              //.unsafeFlags(["-x", "objective-c"], .when(platforms: [.macOS]))])

var glfwTarget = Target.systemLibrary(
  name: "Glfw",
  pkgConfig: "glfw3",
  providers: [
    .brew(["glfw"])]
)

var imguiTarget = Target.target(
  name: "Imgui",
  sources: ["imgui/imconfig.h",
            "imgui/imgui.h",
            "imgui/imgui_demo.cpp",
            "imgui/imgui_draw.cpp",
            "imgui/imgui_tables.cpp",
            "imgui/imstb_rectpack.h",
            "imgui/imstb_truetype.h",
            "imgui/imgui.cpp",
            "imgui/imgui_internal.h",
            "imgui/imgui_widgets.cpp",
            "imgui/imstb_textedit.h",
            "imgui/backends/imgui_impl_glfw.h",
            "imgui/backends/imgui_impl_glfw.cpp"],
  cxxSettings: [.unsafeFlags(["-std=c++17", "-ISources/Imgui/imgui", "-I/opt/homebrew/include"])]
)

let package = Package(
  name: "Z4",
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    glfwTarget,
    imguiTarget,
    sokolTarget,
    .executableTarget(
      name: "Z4",
      dependencies: ["Glfw", "Imgui", "SokolC"],
      swiftSettings: [
        .interoperabilityMode(.Cxx),
        .unsafeFlags(["-I/usr/local/include"], .when(platforms: [.macOS]))
      ],
      linkerSettings: [
        .unsafeFlags(["-L/usr/local/lib"], .when(platforms: [.macOS]))
      ]
    )
  ]
)
