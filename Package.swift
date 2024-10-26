// swift-tools-version: 6.0

import PackageDescription

var sokolTarget = Target.target(
  name: "Sokol",
  sources: ["sokol_impl.mm"],
  cxxSettings: [.define("SOKOL_METAL", .when(platforms: [.macOS])),
                .define("SOKOL_NO_ENTRY"),
                .unsafeFlags([ "-std=c++17"])]
)

var glfwTarget = Target.systemLibrary(
  name: "Glfw",
  pkgConfig: "glfw3",
  providers: [
    .brew(["glfw"])]
)

var handmadeMathTarget = Target.target(
  name: "HandmadeMath",
  sources: ["impl.cpp"],
  cxxSettings: [.unsafeFlags(["-std=c++17"])]
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
  platforms: [
    .macOS(.v10_15)
  ],
  dependencies: [
    .package(url: "https://github.com/tayloraswift/swift-png", from: "4.4.0")
  ],
  targets: [
    glfwTarget,
    handmadeMathTarget,
    imguiTarget,
    sokolTarget,
    .executableTarget(
      name: "Z4",
      dependencies: [
        "Glfw",
        "HandmadeMath",
        "Imgui",
        "Sokol",
        .product(name: "PNG", package: "swift-png")
      ],
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
