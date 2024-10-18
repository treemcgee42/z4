import Metal
import MetalKit

import SokolC
import Glfw

@MainActor
class GlfwGlue {
    var mtlDevice: MTLDevice
    var mtlSwapchain: CAMetalLayer

    var noDepthBuffer: Bool
    var majorVersion: Int32
    var minorVersion: Int32
    var sampleCount: Int32
    var window: OpaquePointer

    init(title: String, width: Int32, height: Int32, noDepthBuffer: Bool,
         mtlDevice: MTLDevice,
         sampleCount: Int32 = 1,
         versionMajor: Int32 = 4, versionMinor: Int32 = 1) {
        self.mtlDevice = mtlDevice
        self.noDepthBuffer = noDepthBuffer
        self.sampleCount = sampleCount
        self.majorVersion = versionMajor
        self.minorVersion = versionMinor

        glfwInit()

        glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
        glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, 0);
        if (noDepthBuffer) {
            glfwWindowHint(GLFW_DEPTH_BITS, 0)
            glfwWindowHint(GLFW_STENCIL_BITS, 0)
        }
        glfwWindowHint(GLFW_SAMPLES, sampleCount == 1 ? 0 : sampleCount)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, versionMajor)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, versionMinor)

        self.mtlSwapchain = CAMetalLayer()
        self.mtlSwapchain.device = self.mtlDevice
        self.mtlSwapchain.isOpaque = true
        self.window = glfwCreateWindow(width, height, title, nil, nil)
        let nsWindow = glfwGetCocoaWindow(window) as! NSWindow
        nsWindow.contentView!.layer = self.mtlSwapchain
        nsWindow.contentView!.wantsLayer = true

        glfwMakeContextCurrent(self.window)
        glfwSwapInterval(1)
    }

    func environment() -> sg_environment {
        return .init(
          defaults: .init(
            color_format: SG_PIXELFORMAT_BGRA8,
            depth_format: self.noDepthBuffer ? SG_PIXELFORMAT_NONE : SG_PIXELFORMAT_DEPTH_STENCIL,
            sample_count: self.sampleCount
          ),
          metal: .init(device: Unmanaged.passUnretained(self.mtlDevice).toOpaque()),
          d3d11: .init(),
          wgpu: .init()
        )
    }

    func swapchain() -> sg_swapchain {
        var width: Int32 = 0
        var height: Int32 = 0
        glfwGetFramebufferSize(self.window, &width, &height)

        var swapchain = sg_swapchain()
        swapchain.width = width
        swapchain.height = height
        swapchain.sample_count = self.sampleCount
        swapchain.color_format = SG_PIXELFORMAT_BGRA8
        swapchain.depth_format = self.noDepthBuffer ? SG_PIXELFORMAT_NONE : SG_PIXELFORMAT_DEPTH_STENCIL
        swapchain.metal.current_drawable = UnsafeRawPointer(Unmanaged.passUnretained(self.mtlSwapchain.nextDrawable()!).toOpaque())
        swapchain.gl = .init(framebuffer: 0)
        return swapchain
    }
}

@MainActor
func main() {
    print("hello, world!")

    let mtlDevice = MTLCreateSystemDefaultDevice()!
    let renderer = GlfwGlue(title: "Hello Triangle", width: 640, height: 480, noDepthBuffer: true,
                            mtlDevice: mtlDevice)

    var sokolDesc = sg_desc()
    sokolDesc.environment = renderer.environment()
    sokolDesc.logger.func = slog_func
    sg_setup(&sokolDesc)

    let vertices: [Float] = [
      // positions            // colors
      0.0,  0.5, 0.5,     1.0, 0.0, 0.0, 1.0,
      0.5, -0.5, 0.5,     0.0, 1.0, 0.0, 1.0,
      -0.5, -0.5, 0.5,     0.0, 0.0, 1.0, 1.0
    ]
    let vertexBuffer = {
        vertices.withUnsafeBufferPointer { ubp in
            let vertexBufferRange = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Float>.size)
            var vertexBufferDesc = sg_buffer_desc()
            vertexBufferDesc.data = vertexBufferRange
            return sg_make_buffer(&vertexBufferDesc)
        }
    }()

    let vertexShader = """
      #include <metal_stdlib>
      using namespace metal;

      struct vs_in {
      float4 position [[attribute(0)]];
      float4 color [[attribute(1)]];
      };
      struct vs_out {
      float4 position [[position]];
      float4 color;
      };

      vertex vs_out _main(vs_in inp [[stage_in]]) {
      vs_out outp;
      outp.position = inp.position;
      outp.color = inp.color;
      return outp;
      }
      """
    let fragmentShader = """
      #include <metal_stdlib>
      using namespace metal;

      fragment float4 _main(float4 color [[stage_in]]) {
      return color;
      };
      """
    let shader: sg_shader = {
        vertexShader.withCString { vs in
            fragmentShader.withCString { fs in
                var shaderDesc = sg_shader_desc()
                shaderDesc.vs.source = vs
                shaderDesc.fs.source = fs
                return sg_make_shader(&shaderDesc)
            }
        }
    }()

    var pipelineDesc = sg_pipeline_desc()
    pipelineDesc.shader = shader
    pipelineDesc.layout.attrs.0.format = SG_VERTEXFORMAT_FLOAT3
    pipelineDesc.layout.attrs.1.format = SG_VERTEXFORMAT_FLOAT4
    let pipeline = sg_make_pipeline(&pipelineDesc)

    var bindings = sg_bindings()
    bindings.vertex_buffers.0 = vertexBuffer

    while (glfwWindowShouldClose(renderer.window) == 0) {
        var pass = sg_pass()
        pass.swapchain = renderer.swapchain()
        sg_begin_pass(&pass)
        sg_apply_pipeline(pipeline);
        sg_apply_bindings(&bindings);
        sg_draw(0, 3, 1);
        sg_end_pass();
        sg_commit();
        glfwSwapBuffers(renderer.window);
        glfwPollEvents();
    }

    sg_shutdown();
    glfwTerminate();
}

main()
