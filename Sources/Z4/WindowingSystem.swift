import Metal

import Glfw
import Imgui
import Sokol

class WindowState {
    private var _windowSize: Size<Int>
    var windowSizeId: PropertyId
    var windowSize: Size<Int> {
        set {
            self._windowSize = newValue
            for (index, reactor) in self.reactors.enumerated().reversed() {
                let removeReactor = reactor(self, self.windowSizeId)
                if removeReactor {
                    self.reactors.remove(at: index)
                }
            }
        }
        get {
            return self._windowSize
        }
    }

    private var _framebufferSize: Size<Int>
    var framebufferSizeId: PropertyId
    var framebufferSize: Size<Int> {
        set {
            self._framebufferSize = newValue
            for (index, reactor) in self.reactors.enumerated().reversed() {
                let removeReactor = reactor(self, self.framebufferSizeId)
                if removeReactor {
                    self.reactors.remove(at: index)
                }
            }
        }
        get {
            return self._framebufferSize
        }
    }

    typealias WindowStateReactor = (_ to: WindowState, _ changedPropertyId: PropertyId) -> Bool
    private var reactors: [WindowStateReactor]

    init() {
        var propertyId = 0

        self._windowSize = .init(width: 0, height: 0)
        self.windowSizeId = propertyId
        propertyId += 1

        self._framebufferSize = .init(width: 0, height: 0)
        self.framebufferSizeId = propertyId
        propertyId += 1

        self.reactors = []
    }

    func registerReactor(_ r: @escaping WindowStateReactor) {
        self.reactors.append(r)
    }
}

@MainActor
class WindowingSystem {
    let windowState: WindowState

    var window: OpaquePointer

    var cocoaWindow: NSWindow
    var mtlDevice: MTLDevice
    var mtlSwapchain: CAMetalLayer

    let depthEnabled = true
    let depthFormat: sg_pixel_format = SG_PIXELFORMAT_DEPTH
    let metalDepthFormat: MTLPixelFormat = .depth32Float
    var depthTexture: MTLTexture?

    var prevFramebufferSize: Size<Int> = .init(width: 0, height: 0)

    init(title: String, size: Size<Int>, mtlDevice: MTLDevice, windowState: WindowState) {
        self.windowState = windowState
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
        self.window = glfwCreateWindow(Int32(size.width), Int32(size.height), title, nil, nil)
        self.cocoaWindow = glfwGetCocoaWindow(window) as! NSWindow
        self.cocoaWindow.contentView!.layer = self.mtlSwapchain
        self.cocoaWindow.contentView!.wantsLayer = true

        glfwMakeContextCurrent(self.window)
        glfwSwapInterval(1)

        glfwSetMouseButtonCallback(self.window, mouseButtonCallback)
        glfwSetCursorPosCallback(self.window, cursorPosCallback)
        glfwSetScrollCallback(self.window, scrollCallback)
        glfwSetKeyCallback(self.window, keyCallback)
        glfwSetWindowFocusCallback(self.window, windowFocusCallback)
        glfwSetCursorEnterCallback(self.window, cursorEnterCallback)
        glfwSetCharCallback(self.window, charCallback)
        glfwSetMonitorCallback(monitorCallback)

        self.windowState.windowSize = self.windowSize()
        self.windowState.framebufferSize = self.framebufferSize()
        self.windowState.registerReactor { [weak self] to, changedPropertyId in
            if self == nil {
                return true
            }

            switch changedPropertyId {
            case to.framebufferSizeId:
                self?.framebufferResizedReactor(newFramebufferSize: to.framebufferSize)
            default:
                break
            }

            return false
        }
    }

    private func createDepthTexture(framebufferSize: Size<Int>) {
        tracer.fnTrace1( "" )
        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: self.metalDepthFormat,
            width: framebufferSize.width,
            height: framebufferSize.height,
            mipmapped: false
        )
        depthDescriptor.usage = [.renderTarget]
        depthDescriptor.storageMode = .private

        self.depthTexture = self.mtlDevice.makeTexture(descriptor: depthDescriptor)
    }

    func dpiScale() -> Float {
        return Float(self.cocoaWindow.backingScaleFactor)
    }

    func windowSize() -> Size<Int> {
        var w: Int32 = 0
        var h: Int32 = 0
        glfwGetWindowSize(self.window, &w, &h)
        return .init(width: Int(w), height: Int(h))
    }

    func framebufferSize() -> Size<Int> {
        var w: Int32 = 0
        var h: Int32 = 0
        glfwGetFramebufferSize(self.window, &w, &h)
        return .init(width: Int(w), height: Int(h))
    }

    func environment() -> sg_environment {
        return .init(
          defaults: .init(
            color_format: SG_PIXELFORMAT_BGRA8,
            depth_format: self.depthFormat,
            sample_count: 1
          ),
          metal: .init(device: Unmanaged.passUnretained(self.mtlDevice).toOpaque()),
          d3d11: .init(),
          wgpu: .init()
        )
    }

    func framebufferResizedReactor(newFramebufferSize: Size<Int>) {
        self.createDepthTexture(framebufferSize: newFramebufferSize)
    }

    func swapchain() -> sg_swapchain {
        let windowSize = self.windowSize()
        let framebufferSize = framebufferSize()
        if self.prevFramebufferSize != framebufferSize {
            tracer.fnTrace1( "window size changed" )
            self.windowState.windowSize = .init(width: windowSize.width, height: windowSize.height)
            self.windowState.framebufferSize = .init(width: framebufferSize.width, height: framebufferSize.height)
        }
        self.prevFramebufferSize = framebufferSize

        self.mtlSwapchain.drawableSize = CGSize(width: framebufferSize.width, height: framebufferSize.height)

        var swapchain = sg_swapchain()
        swapchain.width = Int32(framebufferSize.width)
        swapchain.height = Int32(framebufferSize.height)
        swapchain.sample_count = 1
        swapchain.color_format = SG_PIXELFORMAT_BGRA8
        swapchain.depth_format = self.depthFormat
        let nextDrawable = self.mtlSwapchain.nextDrawable()!
        swapchain.metal.current_drawable = UnsafeRawPointer(Unmanaged.passUnretained(nextDrawable).toOpaque())
        swapchain.metal.depth_stencil_texture = UnsafeRawPointer(Unmanaged.passUnretained(self.depthTexture!).toOpaque())
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

func windowFocusCallback(window: OpaquePointer?, focused: Int32) {
    ImGui_ImplGlfw_WindowFocusCallback(window, focused)
}

func cursorEnterCallback(window: OpaquePointer?, entered: Int32) {
    ImGui_ImplGlfw_CursorEnterCallback(window, entered)
}

func monitorCallback(monitor: OpaquePointer?, event: Int32) {
    ImGui_ImplGlfw_MonitorCallback(monitor, event)
}
