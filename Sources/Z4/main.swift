import Metal
import simd

import Glfw
import HandmadeMath
import Imgui
import Sokol

struct vs_params_t {
    var mvp: HMM_Mat4
}

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

    let windowSize = windowingSystem.windowSize()
    let camera = Camera3dPerspective(
      fov: Measurement(value: 60, unit: UnitAngle.degrees), aspectRatio: Float(windowSize.width)/Float(windowSize.height), near: 0.01, far: 10.0,
      lookFrom: HMM_Vec3(Elements: (0.0, 1.5, 6.0)), lookAt: HMM_Vec3(Elements: (0.0, 0.0, 0.0)), upDirection: HMM_Vec3(Elements: (0.0, 1.0, 0.0)))
    let shaderManager = ShaderManager()
    
    let vertices: [Float] = [
      // positions            // colors
      -1.0, -1.0, -1.0,   1.0, 0.0, 0.0, 1.0,
       1.0, -1.0, -1.0,   1.0, 0.0, 0.0, 1.0,
       1.0,  1.0, -1.0,   1.0, 0.0, 0.0, 1.0,
      -1.0,  1.0, -1.0,   1.0, 0.0, 0.0, 1.0,

      -1.0, -1.0,  1.0,   0.0, 1.0, 0.0, 1.0,
       1.0, -1.0,  1.0,   0.0, 1.0, 0.0, 1.0,
       1.0,  1.0,  1.0,   0.0, 1.0, 0.0, 1.0,
      -1.0,  1.0,  1.0,   0.0, 1.0, 0.0, 1.0,

      -1.0, -1.0, -1.0,   0.0, 0.0, 1.0, 1.0,
      -1.0,  1.0, -1.0,   0.0, 0.0, 1.0, 1.0,
      -1.0,  1.0,  1.0,   0.0, 0.0, 1.0, 1.0,
      -1.0, -1.0,  1.0,   0.0, 0.0, 1.0, 1.0,

       1.0, -1.0, -1.0,   1.0, 0.5, 0.0, 1.0,
       1.0,  1.0, -1.0,   1.0, 0.5, 0.0, 1.0,
       1.0,  1.0,  1.0,   1.0, 0.5, 0.0, 1.0,
       1.0, -1.0,  1.0,   1.0, 0.5, 0.0, 1.0,

      -1.0, -1.0, -1.0,   0.0, 0.5, 1.0, 1.0,
      -1.0, -1.0,  1.0,   0.0, 0.5, 1.0, 1.0,
       1.0, -1.0,  1.0,   0.0, 0.5, 1.0, 1.0,
       1.0, -1.0, -1.0,   0.0, 0.5, 1.0, 1.0,

      -1.0,  1.0, -1.0,   1.0, 0.0, 0.5, 1.0,
      -1.0,  1.0,  1.0,   1.0, 0.0, 0.5, 1.0,
       1.0,  1.0,  1.0,   1.0, 0.0, 0.5, 1.0,
       1.0,  1.0, -1.0,   1.0, 0.0, 0.5, 1.0
    ]
    let vertexBuffer = {
        vertices.withUnsafeBufferPointer { ubp in
            let vertexBufferRange = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Float>.size)
            var vertexBufferDesc = sg_buffer_desc()
            vertexBufferDesc.data = vertexBufferRange
            return sg_make_buffer(&vertexBufferDesc)
        }
    }()

    let indices: [Int16] = [
      0, 1, 2,  0, 2, 3,
      6, 5, 4,  7, 6, 4,
      8, 9, 10,  8, 10, 11,
      14, 13, 12,  15, 14, 12,
      16, 17, 18,  16, 18, 19,
      22, 21, 20,  23, 22, 20
    ]
    let indexBuffer = {
        indices.withUnsafeBufferPointer { ubp in
            let range = sg_range(ptr: ubp.baseAddress, size: ubp.count * MemoryLayout<Int16>.size)
            var desc = sg_buffer_desc()
            desc.type = SG_BUFFERTYPE_INDEXBUFFER
            desc.data = range
            return sg_make_buffer(&desc)
        }
    }()

    let vertexShaderSource = shaderManager.getSource(shaderName: "simple-vs")
    let fragmentShader = """
      #include <metal_stdlib>
      using namespace metal;

      fragment float4 _main(float4 color [[stage_in]]) {
          return color;
      };
      """
    let shader: sg_shader = {
        vertexShaderSource.withCString{ vs in 
            fragmentShader.withCString { fs in
                var shaderDesc = sg_shader_desc()
                shaderDesc.vs.source = vs
                shaderDesc.vs.uniform_blocks.0.size = MemoryLayout<vs_params_t>.size
                shaderDesc.fs.source = fs
                return sg_make_shader(&shaderDesc)
            }
        }
    }()

    var pipelineDesc = sg_pipeline_desc()
    pipelineDesc.shader = shader
    pipelineDesc.layout.attrs.0.format = SG_VERTEXFORMAT_FLOAT3
    pipelineDesc.layout.attrs.1.format = SG_VERTEXFORMAT_FLOAT4
    pipelineDesc.index_type = SG_INDEXTYPE_UINT16
    pipelineDesc.depth.compare = SG_COMPAREFUNC_LESS_EQUAL
    pipelineDesc.depth.write_enabled = true
    pipelineDesc.cull_mode = SG_CULLMODE_BACK
    let pipeline = sg_make_pipeline(&pipelineDesc)

    var bindings = sg_bindings()
    bindings.vertex_buffers.0 = vertexBuffer
    bindings.index_buffer = indexBuffer

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
        camera.imguiDebugWindow()

        ImGui.ShowDemoWindow();

        sg_begin_pass(&pass)
        sg_apply_pipeline(pipeline);
        sg_apply_bindings(&bindings);
        var vs_params = vs_params_t(mvp: camera.viewProjectionMatrix)
        withUnsafeBytes(of: &vs_params) { buffer in
            var range = sg_range(ptr: buffer.baseAddress, size: buffer.count)
            sg_apply_uniforms(SG_SHADERSTAGE_VS, 0, &range)
        }
        sg_draw(0, 36, 1);
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
