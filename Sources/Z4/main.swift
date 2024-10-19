import Metal

import Imgui
import Glfw
import Sokol

@MainActor
func main() {
    print("hello, world!")

    let mtlDevice = MTLCreateSystemDefaultDevice()!
    let windowingSystem = WindowingSystem(title: "Hello Triangle", width: 640, height: 480, mtlDevice: mtlDevice)

    var sokolDesc = sg_desc()
    sokolDesc.environment = windowingSystem.environment()
    sokolDesc.logger.func = slog_func
    sg_setup(&sokolDesc)

    var sokolImguiDesc = simgui_desc_t()
    sokolImguiDesc.logger.func = slog_func
    simgui_setup(&sokolImguiDesc)

    ImGui_ImplGlfw_InitForOther(windowingSystem.window, false);

    stm_setup();
    
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

    var lastTime: UInt64 = 0
    while (glfwWindowShouldClose(windowingSystem.window) == 0) {
        var pass = sg_pass()
        pass.swapchain = windowingSystem.swapchain()

        var sokolImguiFrameDesc = simgui_frame_desc_t()
        sokolImguiFrameDesc.width = Int32(pass.swapchain.width)
        sokolImguiFrameDesc.height = Int32(pass.swapchain.height)
        sokolImguiFrameDesc.delta_time = stm_sec(stm_laptime(&lastTime));
        sokolImguiFrameDesc.dpi_scale = windowingSystem.dpiScale()
        simgui_new_frame(&sokolImguiFrameDesc);

        withVaList([], { vaList in 
                           ImGui.TextV("Hello", vaList); })
        ImGui.ShowDemoWindow();
        
        sg_begin_pass(&pass)
        sg_apply_pipeline(pipeline);
        sg_apply_bindings(&bindings);
        sg_draw(0, 3, 1);
        simgui_render();
        sg_end_pass();
        sg_commit();
        glfwSwapBuffers(windowingSystem.window);
        glfwPollEvents();
    }

    ImGui_ImplGlfw_Shutdown()
    simgui_shutdown();
    sg_shutdown();
    glfwTerminate();
}

main()
