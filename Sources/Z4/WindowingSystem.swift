import Metal

import Glfw
import Imgui
import SokolC

@MainActor
class WindowingSystem {
    var window: OpaquePointer

    var cocoaWindow: NSWindow
    var mtlDevice: MTLDevice
    var mtlSwapchain: CAMetalLayer

    init(title: String, width: Int32, height: Int32, mtlDevice: MTLDevice) {
        self.mtlDevice = mtlDevice

        glfwInit()

        glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
        glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, 1);
        glfwWindowHint(GLFW_DEPTH_BITS, 0)
        glfwWindowHint(GLFW_STENCIL_BITS, 0)
        glfwWindowHint(GLFW_SAMPLES, 0)

        self.mtlSwapchain = CAMetalLayer()
        self.mtlSwapchain.device = self.mtlDevice
        self.mtlSwapchain.isOpaque = true
        self.window = glfwCreateWindow(width, height, title, nil, nil)
        self.cocoaWindow = glfwGetCocoaWindow(window) as! NSWindow
        self.cocoaWindow.contentView!.layer = self.mtlSwapchain
        self.cocoaWindow.contentView!.wantsLayer = true

        glfwMakeContextCurrent(self.window)
        glfwSwapInterval(1)

        glfwSetMouseButtonCallback(self.window, mouseButtonCallback)
        glfwSetCursorPosCallback(self.window, cursorPosCallback)
        glfwSetScrollCallback(self.window, scrollCallback)
        glfwSetKeyCallback(self.window, keyCallback)
    }

    func dpiScale() -> Float {
        return Float(self.cocoaWindow.backingScaleFactor)
    }

    func windowSize() -> (width: Int, height: Int) {
        var w: Int32 = 0
        var h: Int32 = 0
        glfwGetWindowSize(self.window, &w, &h)
        return (width: Int(w), height: Int(h))
    }

    func framebufferSize() -> (width: Int, height: Int) {
        var w: Int32 = 0
        var h: Int32 = 0
        glfwGetFramebufferSize(self.window, &w, &h)
        return (width: Int(w), height: Int(h))
    }

    func environment() -> sg_environment {
        return .init(
          defaults: .init(
            color_format: SG_PIXELFORMAT_BGRA8,
            depth_format: SG_PIXELFORMAT_NONE,
            sample_count: 1
          ),
          metal: .init(device: Unmanaged.passUnretained(self.mtlDevice).toOpaque()),
          d3d11: .init(),
          wgpu: .init()
        )
    }

    func swapchain() -> sg_swapchain {
        let framebufferSize = self.framebufferSize()
        self.mtlSwapchain.drawableSize = CGSize(width: framebufferSize.width, height: framebufferSize.height)
        
        var swapchain = sg_swapchain()
        swapchain.width = Int32(framebufferSize.width)
        swapchain.height = Int32(framebufferSize.height)
        swapchain.sample_count = 1
        swapchain.color_format = SG_PIXELFORMAT_BGRA8
        swapchain.depth_format = SG_PIXELFORMAT_NONE
        let nextDrawable = self.mtlSwapchain.nextDrawable()!
        swapchain.metal.current_drawable = UnsafeRawPointer(Unmanaged.passUnretained(nextDrawable).toOpaque())
        return swapchain
    }
}

func mouseButtonCallback(window: OpaquePointer?, button: Int32, action: Int32, mods: Int32) {
    ImGui_ImplGlfw_MouseButtonCallback(window, button, action, mods)
}

func cursorPosCallback(window: OpaquePointer?, posX: Double, posY: Double) {
    ImGui_ImplGlfw_CursorPosCallback(window, posX, posY)
}

func scrollCallback(window: OpaquePointer?, posX: Double, posY: Double) {
    ImGui_ImplGlfw_ScrollCallback(window, posX, posY)
}

func keyCallback(window: OpaquePointer?, key: Int32, scanCode: Int32, action: Int32, mods: Int32) {
    ImGui_ImplGlfw_KeyCallback(window, key, scanCode, action, mods)
}

func charCallback(window: OpaquePointer?, codepoint: UInt32) {
    ImGui_ImplGlfw_CharCallback(window, codepoint)
}
